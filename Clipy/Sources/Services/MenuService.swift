// 
//  MenuService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
// 
//  Created by 胡继续 on 2019/8/13.
// 
//  Copyright © 2015-2019 Clipy Project.
//

import Foundation
import Cocoa
import RealmSwift
import RxRealm
import RxSwift
import RxOptional
import RxRelay
import PINCache

final class MenuService {
    
    // MARK: - Properties
    static let shared = MenuService()
    
    fileprivate let historyMenu = BehaviorRelay<NSMenu>(value: NSMenu())
    fileprivate let shortenSymbol = "..."
    fileprivate let kMaxKeyEquivalents = 10
    fileprivate let textIcon = Asset.iconText.image.iconize()
    fileprivate var clipDisposeBag = DisposeBag()
    
    private func observeClips(ascending: Bool) {
        let realm = try! Realm()
        let clips = realm.objects(CPYClip.self)
            .sorted(byKeyPath: #keyPath(CPYClip.updateTime), ascending: ascending)
        Observable.collection(from: clips)
            .map { [weak self] clips in self?.makeMenu(with: clips) }
            .filterNil()
            .bind(to: historyMenu)
            .disposed(by: clipDisposeBag)
        
    }
}


fileprivate extension MenuService {
    func makeMenu(with clips: Results<CPYClip>) -> NSMenu {
        let options = MenuOptions()
        let allHistories = clips.prefix(options.maxHistorySize)
        let items = allHistories.enumerated()
            .compactMap { [weak self] (index, clip) in self?.makeMenuItem(clip: clip, options: options, index: index) }

        let menu = NSMenu(title: Constants.Menu.clip)

        let historyItem = NSMenuItem(title: L10n.history, action: nil)
        historyItem.isEnabled = false
        menu.addItem(historyItem)
        // Inline clips
        items.prefix(options.numberOfItemsPlaceInline).forEach { item in menu.addItem(item) }
        // Folder clips
        items.enumerated()
            .dropFirst(options.numberOfItemsPlaceInline)
            .split { offset, _ -> Bool in
                (offset - options.numberOfItemsPlaceInline + 1) % options.numberOfItemsPlaceInsideFolder == 0
            }
        return menu
    }

    func makeMenuItem(clip: CPYClip, options: MenuOptions, index: Int) -> NSMenuItem {
        let listNumber = index < options.numberOfItemsPlaceInline ? index : ((index - options.numberOfItemsPlaceInline) % options.numberOfItemsPlaceInsideFolder)
        let shortcutNumber = (options.menuItemsTitleStartWithZero ? listNumber : listNumber + 1) % kMaxKeyEquivalents

        let keyEquivalent = options.addNumbericKeyEquivalents ? "\(shortcutNumber)" : ""

        var title = trimTitle(clip.title, postfix: shortenSymbol, len: options.maxMenuItemTitleLength)
        let pbType = NSPasteboard.PasteboardType(rawValue: clip.primaryType)
        if title.isNotEmpty {
            // noop
        } else if pbType.isTIFF {
            title = "(Image)"
        } else if pbType.isPDF {
            title = "(PDF)"
        } else if pbType.isFilenames {
            title = "(Filenames)"
        }
        let itemTitle = menuItemTitle(title, num: shortcutNumber, isMarkWithNumber: options.menuItemsAreMarkedWithNumbers)
        let item = NSMenuItem(title: itemTitle, action: #selector(AppDelegate.selectClipMenuItem(_:)), keyEquivalent: keyEquivalent)
        item.representedObject = clip.dataHash

        if options.showToolTipOnMenuItem {
            item.toolTip = trimTitle(clip.title, postfix: shortenSymbol, len: options.maxLengthOfToolTip)
        }

        if options.showImageInTheMenu {
            item.image = textIcon
        } else if clip.isColorCode && options.showColorPreviewInTheMenu {
            item.image = textIcon
        }

        if clip.thumbnailPath.isNotEmpty, item.image != nil {
            PINCache.shared().object(forKey: clip.thumbnailPath) {[weak item]_,_,object in
                DispatchQueue.main.async {
                    item?.image = object as? NSImage
                }
            }
        }

        return item
    }
    
    func trimTitle(_ title: String, postfix: String = "", len: Int) -> String {
        if title.isEmpty { return "" }
        let ln = max(postfix.count, len)
        if title.count <= ln {
            return title
        }
        let idx = title.index(title.startIndex, offsetBy: ln - postfix.count)
        return title[..<idx] + postfix
    }
    
    func menuItemTitle(_ title: String, num: Int, isMarkWithNumber: Bool) -> String {
        return (isMarkWithNumber) ? "\(num). \(title)" : title
    }
}

private class MenuOptions {
    let maxHistorySize = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
    let numberOfItemsPlaceInline = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInline)
    let menuItemsTitleStartWithZero = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsTitleStartWithZero)
    let numberOfItemsPlaceInsideFolder = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInsideFolder)
    let menuItemsAreMarkedWithNumbers = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsAreMarkedWithNumbers)
    let showToolTipOnMenuItem = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showToolTipOnMenuItem)
    let showImageInTheMenu = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showImageInTheMenu)
    let showColorPreviewInTheMenu = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showColorPreviewInTheMenu)
    let addNumbericKeyEquivalents = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents)
    let maxMenuItemTitleLength = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
    let maxLengthOfToolTip = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxLengthOfToolTip)
}

private extension NSImage {
    func iconize(_ width: CGFloat = 15, _ height: CGFloat = 13) -> NSImage {
        isTemplate = true
        size = CGSize(width: width, height: height)
        return self
    }
}

// 
//  PasteboardTypeSpec.swift
//
//  ClipyTests
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
// 
//  Created by 胡继续 on 2019/8/12.
// 
//  Copyright © 2015-2019 Clipy Project.
//

import Foundation
import Quick
import Nimble
@testable import Clipy

class PasteboardTypeSpec: QuickSpec {
    override func spec() {
        // swiftlint:disable quick_discouraged_call
        AvailableType.allCases.forEach { type in
            describe("AvailableType." + type.rawValue) {
                type.targetPbTypes.forEach { pbType in
                    it(pbType.rawValue) {
                        expect(pbType.isString) == type.isString
                        expect(pbType.isRTF) == type.isRTF
                        expect(pbType.isRTFD) == type.isRTFD
                        expect(pbType.isPDF) == type.isPDF
                        expect(pbType.isFilenames) == type.isFilenames
                        expect(pbType.isURL) == type.isURL
                    }
                }
            }
        }
        // swiftlint:enable quick_discouraged_call

        describe("Menu Generate") {
            it("10, 10, 33") {
                let first = 11
                let each = 10
                let items = 0..<33
                items.prefix(first).enumerated().forEach { offset, element in
                    expect(element) == offset
                }
                let folders = items
                    .enumerated()
                    .dropFirst(first)
                    .map { $0 }
                    .chunk(size: each)

                let remain = items.count - first
                expect(folders.count) == remain / each + (remain % each > 0 ? 1 : 0)
                expect(folders[0].first?.offset) == first
                expect(folders[0].last?.offset) == first + each - 1
                expect(folders[1][0].offset) == first + each
                expect(folders[1].last?.offset) == first + each * 2 - 1
                expect(folders[2][0].offset) == first + each * 2
                expect(folders[2].last?.offset) == Swift.min(first + each * 3 - 1, items.count - 1)

            }
        }
    }
}

extension Collection {
    func chunk(size: Int) -> [[Element]] {
        return Swift.stride(from: 0, to: self.count, by: size)
            .map { idx in
                let start = self.index(self.startIndex, offsetBy: idx)
                let end = self.index(self.startIndex, offsetBy: Swift.min(idx + size, self.count))
                return Array(self[start..<end])
            }
    }
}

extension Array {
    func chunk(size: Int) -> [[Element]] {
        return Swift.stride(from: 0, to: self.count, by: size)
            .map { idx in
                return Array(self[idx..<(Swift.min(idx + size, self.count))])
            }
    }
}

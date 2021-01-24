xcodebuild -resolvePackageDependencies -workspace Clipy.xcworkspace -scheme Clipy -configuration Release -clonedSourcePackagesDirPath SourcePackages

set -o pipefail && xcodebuild -workspace Clipy.xcworkspace -scheme Clipy -configuration Release -clonedSourcePackagesDirPath SourcePackages -destination 'generic/platform=macOS' -archivePath Clipy.xcarchive CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' clean archive | xcpretty

rm -rf Clipy.app* && cp -rf Clipy.xcarchive/Products/Applications/Clipy.app ./

zip -ry Clipy.app.zip Clipy.app
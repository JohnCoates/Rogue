set -x
set -e

scriptsDirectory=`dirname "$0"`
projectDirectory="$scriptsDirectory/../"

pushd "$projectDirectory"
    xcodebuild archive -project ./RogueFramework.xcodeproj -scheme Rogue -configuration Release -destination "generic/platform=iOS" \
    -archivePath "./build/ios.xcarchive"
    xcodebuild archive -project ./RogueFramework.xcodeproj -scheme Rogue -configuration Release -destination "generic/platform=iOS Simulator" \
    -archivePath "./build/ios-simulator.xcarchive"
    
    subpath="/Products/Library/Frameworks/Rogue.framework"
    xcodebuild -create-xcframework -framework "./build/ios.xcarchive/$subpath" -framework "./build/ios-simulator.xcarchive/$subpath" \
    -output ./build/Rogue.xcframework
popd
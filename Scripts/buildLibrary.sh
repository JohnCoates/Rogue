set -x
set -e

scriptsDirectory=`dirname "$0"`
projectDirectory="$scriptsDirectory/../"

pushd "$projectDirectory"
    xcodebuild -scheme Rogue -project RogueFramework.xcodeproj -sdk iphoneos -configuration Release -arch arm64e DISTRIBUTING=YES WRAPPER_EXTENSION="temp"
    xcodebuild -scheme Rogue -project RogueFramework.xcodeproj -sdk iphoneos -configuration Release -arch arm64 DISTRIBUTING=YES WRAPPER_EXTENSION="temp"
    xcodebuild -scheme Rogue -project RogueFramework.xcodeproj -sdk iphoneos -configuration Release -arch armv7 DISTRIBUTING=YES WRAPPER_EXTENSION="temp"
    xcodebuild -scheme Rogue -project RogueFramework.xcodeproj -sdk iphonesimulator -configuration Release -arch x86_64 DISTRIBUTING=YES WRAPPER_EXTENSION="temp"
popd

pushd "$projectDirectory/build"
    libtool -static Rogue.arm64e.a Rogue.arm64.a Rogue.armv7.a Rogue.x86_64.a -o Rogue.temp/Rogue
    mv Rogue.temp Rogue.framework
popd
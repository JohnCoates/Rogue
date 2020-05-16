scriptsDirectory=`dirname "$0"`
projectDirectory=`dirname "$scriptsDirectory"`

set -x

pushd "$projectDirectory"
    xcodebuild -scheme Rogue -project RogueLibrary.xcodeproj -sdk iphoneos -configuration Release -arch arm64e
    xcodebuild -scheme Rogue -project RogueLibrary.xcodeproj -sdk iphoneos -configuration Release -arch arm64
    xcodebuild -scheme Rogue -project RogueLibrary.xcodeproj -sdk iphoneos -configuration Release -arch armv7
    xcodebuild -scheme Rogue -project RogueLibrary.xcodeproj -sdk iphonesimulator -configuration Release -arch x86_64
popd

pushd "$projectDirectory/build"
    libtool -static Rogue.arm64e.a Rogue.arm64.a Rogue.armv7.a Rogue.x86_64.a -o Rogue.a
popd

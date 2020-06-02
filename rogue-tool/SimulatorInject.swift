//
//  SimulatorInject.swift
//  Created on 5/15/20
//

import Foundation
import ArgumentParser

extension RogueTool {
    struct SimulatorInjectCommand: ParsableCommand {
        static var configuration =
            CommandConfiguration(commandName: "simulator-inject", abstract: "Inject into iOS simulator.")

        @Flag(name: .long, help: "Whether the injection library should always be built. (development)")
        var build: Bool

        @Option(name: .long, help: "The Property List file that filters what targets are injected into.")
        var filterFile: String

        @Option(name: .customLong("library"), help: "The library to be injected.")
        var libraries: [String]

        func run() {
            let injectionLibrary = buildLibrary()
            print("Injecting loader \(injectionLibrary)")

            libraries.forEach { library in
                assert(FileManager.default.fileExists(atPath: library), "warning: \(library) doesn't exist")
            }

            assert(FileManager.default.fileExists(atPath: filterFile), "warning: \(filterFile) doesn't exist")

            System.runLight("xcrun simctl spawn booted launchctl setenv ROGUE_LIBRARY \"\(libraries.joined(separator:"|"))\"")
            System.runLight("xcrun simctl spawn booted launchctl setenv ROGUE_FILTER \"\(filterFile)\"")

            setenv("SIMCTL_CHILD_DYLD_INSERT_LIBRARIES", injectionLibrary, 1)
            ["DYLD_INSERT_LIBRARIES", "__XPC_DYLD_INSERT_LIBRARIES"].forEach { key in
                System.runLight("xcrun simctl spawn booted launchctl setenv \(key) \"\(injectionLibrary)\"")
            }

            System.runLight("xcrun simctl spawn booted launchctl stop com.apple.backboardd")
        }

        func injectIntoDevices() {

        }

        func buildLibrary() -> String {
            let projectDirectory = RunState.projectDirectory

            return RunState.inWorkingDirectory(directory: projectDirectory) { () -> String in
                return buildLibrary_Xcode(directory: projectDirectory)
//                return buildLibrary_Package(directory: directory)
            }
        }

        let product = "RogueToolLibrary"
        let filename = "libRogueToolLibrary.dylib"
        func buildLibrary_Xcode(directory: String) -> String {
            let projectFile = "RogueToolLibrary.xcodeproj"
            let filePath = directory + "/derived/Build/Products/Release-iphonesimulator/RogueToolLibrary.dylib"
            if build == false && FileManager.default.fileExists(atPath: filePath) {
                print("Library exists, skipping build")
                return filePath
            }

            print("Building \(product)")
            let builtLibrary = System.runLight("xcodebuild -project \(projectFile) -scheme \(product) " +
                "-configuration Release " +
                "-sdk iphonesimulator -derivedDataPath ./derived CODE_SIGNING_ALLOWED=NO")
            precondition(builtLibrary, "Failed to build \(product)")
            precondition(FileManager.default.fileExists(atPath: filePath), "Library doesn't exist at \(filePath).")
            return filePath
        }

        func buildLibrary_Package(directory: String) -> String {
            var filePathMaybe: String?
            // swift build --product RogueToolLibrary --configuration release \
            // -Xswiftc "-sdk" -Xswiftc \(sdkPath) \
            // -Xswiftc "-target" -Xswiftc "x86_64-apple-ios13.0-simulator"
            let buildCommand = "swift build --product \(product) --configuration release"
            System.run("\(buildCommand) --show-bin-path") { result in
                let directory = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                filePathMaybe = directory + "/\(self.filename)"
            }

            guard let filePath = filePathMaybe else {
                fatalError("Failed to get library path.")
            }

            if build == false && FileManager.default.fileExists(atPath: filePath) {
                print("Library exists, skipping build.")
                return filePath
            }

            System.run(buildCommand) { result in
                if result.exitCode != 0 {
                    fatalError("Error: Failed command exit code: \(result.exitCode)")
                }
            }

            return filePath
        }
    }
}

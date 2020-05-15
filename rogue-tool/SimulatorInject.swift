//
//  SimulatorInject.swift
//  Created on 5/15/20
//

import Foundation
import ArgumentParser

extension RougeTool {
    struct SimulatorInject: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "Inject into iOS simulator.")

        @Argument(
            help: "Path to library to inject.")
        var library: String

        func run() {
            print("Injecting: \(library)")
            let device = "D7960CDD-217A-4757-B2ED-D6B048FE2C4B"

            System.run("xcrun simctl spawn \(device) launchctl setenv DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib") { result in
                if result.exitCode != 0 {
                    print("Failed command exit code: \(result.exitCode)")
                }
            }
        }
    }
}

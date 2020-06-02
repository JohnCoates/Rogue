//
//  PackageCommand.swift
//  Created on 6/2/20
//

import Foundation
import ArgumentParser

struct PackageCommand: ParsableCommand {
    static var configuration =
        CommandConfiguration(commandName: "package", abstract: "Make .deb file.")

    @Option(name: .customLong("project-directory"), help: "The project directory.")
    var projectDirectory: String

    @Option(name: .customLong("library"), help: "The library to be injected.")
    var library: String

    @Option(name: .long, help: "The Property List file that filters what targets are injected into.")
    var filter: String

    @Option(name: .customLong("control"), help: "The package description file.")
    var control: String

    @Option(name: .customLong("version"), help: "The package version.")
    var version: String

    @Flag(name: .long, help: "Install the .deb to a device")
    var install: Bool

    @Option(name: .long, help: "Application to terminate on install.")
    var terminate: [String]

    func run() {
        let package = buildPackage()
        if install {
            install(package: package)
        }
    }

    func buildPackage() -> URL {
        let projectDirectory = URL(fileURLWithPath: self.projectDirectory)
        let derivedData = projectDirectory.appendingPathComponent("DerivedData")
        let buildDirectory = derivedData.appendingPathComponent("RogueBuild")
        let stagingDirectory = buildDirectory.appendingPathComponent("staging")
        let debianDirectory = stagingDirectory.appendingPathComponent("DEBIAN")
        let dynamicLibrariesDirectory = stagingDirectory.appendingPathComponent("Library/MobileSubstrate/DynamicLibraries")
        let productsDirectory = derivedData.appendingPathComponent("Products")

        let requiredDirectories = [
            stagingDirectory,
            debianDirectory,
            dynamicLibrariesDirectory,
            productsDirectory
        ]
        let fileManager = FileManager.default
        for directory in requiredDirectories {
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    try fileManager.createDirectory(atPath: directory.path, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    fatalError("Error: Failed creating \(directory): \(error)")
                }
            }
        }

        let libraryUrl = URL(fileURLWithPath: library)
        let controlUrl = URL(fileURLWithPath: control)
        let filterUrl = URL(fileURLWithPath: filter)
        let baseName = libraryUrl.lastPathComponent.split(separator: ".")[0]

        let copyFiles = [
            libraryUrl: dynamicLibrariesDirectory.appendingPathComponent(libraryUrl.lastPathComponent),
            filterUrl: dynamicLibrariesDirectory.appendingPathComponent("\(baseName).plist"),
            controlUrl: debianDirectory.appendingPathComponent("control")
        ]
        for (source, destination) in copyFiles {
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: source, to: destination)
            } catch let error {
                fatalError("Error: Failed to copy \(source.path) to \(destination.path): \(error)")
            }
        }

        let packageUrl = productsDirectory.appendingPathComponent(baseName + "_" + version + ".deb")
        System.runLight("/usr/local/bin/dpkg-deb -b -Zgzip \"\(stagingDirectory.path)\" \"\(packageUrl.path)\"")
        return packageUrl
    }

    var deviceIp: String? {
        let environment = ProcessInfo.processInfo.environment
        if let ip = environment["ROGUE_DEVICE_HOST"] {
            return ip
        } else if let ip = environment["THEOS_DEVICE_HOST"] {
            return ip
        }

        return nil
    }

    var devicePort: Int {
        let environment = ProcessInfo.processInfo.environment
        if let portString = environment["ROGUE_DEVICE_PORT"], let port = Int(portString) {
            return port
        } else if let portStirng = environment["THEOS_DEVICE_PORT"], let port = Int(portStirng) {
            return port
        }

        return 22
    }

    func install(package: URL) {
        guard let deviceIp = deviceIp else {
            fatalError("Error: Can't install on device, no device IP specified. Check Xcode build settings or set environment variable ROGUE_DEVICE_HOST.")
        }
        let filename = package.lastPathComponent
        print("Warning: Transferring \(filename) to \(deviceIp)")
        System.runLight("scp -P \(devicePort) \"\(package.path)\" root@\(deviceIp):\(filename)")
        print("Warning: Installing package")
        System.runLight("ssh -p \(devicePort) root@\(deviceIp) \"dpkg -i \(filename)\"")

        let terminate = self.terminate.map({"\"\($0)\""}).joined(separator: " ")
        System.runLight("ssh -p \(devicePort) root@\(deviceIp) \"killall \(terminate)\"")
    }
}
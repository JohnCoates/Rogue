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
                    fatalError("error: Failed creating \(directory): \(error)")
                }
            }
        }

        let libraryUrl = URL(fileURLWithPath: library)
        let controlUrl = URL(fileURLWithPath: control)
        let filterUrl = URL(fileURLWithPath: filter)
        let baseName = libraryUrl.lastPathComponent.split(separator: ".")[0]

        let libraryDestination = dynamicLibrariesDirectory.appendingPathComponent(libraryUrl.lastPathComponent)
        let copyFiles = [
            libraryUrl: libraryDestination,
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
                fatalError("error: Failed to copy \(source.path) to \(destination.path): \(error)")
            }
        }

        print("warning: Codesigning")
        System.runLight("xcrun codesign -f -s - \"\(libraryDestination.path)\"")

        let dpkgPath = "/usr/local/bin/dpkg-deb"
        if !fileManager.fileExists(atPath: dpkgPath) {
            let brewPath = "/usr/local/bin/brew"
            if fileManager.fileExists(atPath: brewPath) {
                print("warning: dpkg not installed, installing with Homebrew")
                System.runLight("\(brewPath) install dpkg")
            }

            if !fileManager.fileExists(atPath: dpkgPath) {
                print("error: Can't build package, dpkg not installed.")
                print("error: Install dpkg with Homebrew from https://brew.sh")
                print("error: run `brew install dpkg`")
                fatalError("error: install dpkg before running again")
            }
        }

        let packageUrl = productsDirectory.appendingPathComponent(baseName + "_" + version + ".deb")
        System.runLight("\(dpkgPath) -b -Zgzip \"\(stagingDirectory.path)\" \"\(packageUrl.path)\"")
        return packageUrl
    }

    var deviceHost: String? {
        let environment = ProcessInfo.processInfo.environment
        if let host = environment["ROGUE_DEVICE_HOST"], host.count > 0 {
            return host
        } else if let host = environment["THEOS_DEVICE_IP"], host.count > 0 {
            return host
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

    var devicePassword: String? {
        let environment = ProcessInfo.processInfo.environment
        if let password = environment["ROGUE_DEVICE_PASSWORD"], password.count > 0 {
            return password
        }

        return nil
    }

    func install(package: URL) {
        guard let deviceHost = deviceHost else {
            fatalError("error: Can't install on device, no device host specified. Check Xcode build settings or set environment variable ROGUE_DEVICE_HOST.")
        }

        var passwordCommand = ""
        if let devicePassword = devicePassword {
            let sshPassPath = self.sshPassPath()
            passwordCommand = "\(sshPassPath) -p \"\(devicePassword)\" "
        }
        let filename = package.lastPathComponent
        print("warning: Transferring \(filename) to \(deviceHost)")
        System.runLight(passwordCommand + "scp -P \(devicePort) \"\(package.path)\" root@\(deviceHost):\(filename)")
        print("warning: Installing package")
        System.runLight(passwordCommand + "ssh -p \(devicePort) root@\(deviceHost) \"dpkg -i \(filename)\"")

        let terminate = self.terminate.map({"\"\($0)\""}).joined(separator: " ")
        System.runLight(passwordCommand + "ssh -p \(devicePort) root@\(deviceHost) \"killall \(terminate)\"")
    }

    func sshPassPath() -> String {
        let fileManager = FileManager.default
        let path = "/usr/local/bin/sshpass"
        if !fileManager.fileExists(atPath: path) {
            let brewPath = "/usr/local/bin/brew"
            if fileManager.fileExists(atPath: brewPath) {
                print("warning: sshpass not installed, installing with Homebrew")
                System.runLight("\(brewPath) install hudochenkov/sshpass/sshpass ")
            }

            if !fileManager.fileExists(atPath: path) {
                print("error: Can't install package with password, sshpass not installed.")
                print("error: Install sshpass with Homebrew from https://brew.sh")
                print("error: run `brew install hudochenkov/sshpass/sshpass`")
                fatalError("error: install sshpass before running again")
            }
        }

        return path
    }
}

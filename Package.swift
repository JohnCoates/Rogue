// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.macOS(.v10_10),
                .iOS(.v9)],
    products: [
        .library(name: "Rogue", type: .`static`, targets: ["Rogue"]),
        .executable(name: "rogue-tool", targets: ["rogue-tool"]),
        .library(name: "RogueToolLibrary", targets: ["Rogue"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1")
    ],
    targets: [
        .target(name: "Rogue", dependencies: [], path: "Rogue", publicHeadersPath: "",
        cSettings: [.headerSearchPath("Hook"),
                    .headerSearchPath("Utilities")]),
        .target(name: "rogue-tool", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ], path: "rogue-tool"),

        .target(name: "RogueToolLibrary", dependencies: [], path: "RogueToolLibrary")
    ]
)

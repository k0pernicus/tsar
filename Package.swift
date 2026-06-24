// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tsar",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/kateinoigakukun/swift-tar",
            revision: "642cd916016ca6dd8fab8232f31f9fdb459e27b0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "tsar",
            dependencies: [
                .product(name: "Tar", package: "swift-tar"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "tsarTests",
            dependencies: ["tsar"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

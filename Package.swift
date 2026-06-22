// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebResponse",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WebResponse",
            targets: ["WebResponse"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", .upToNextMajor(from: "3.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WebResponse",
            swiftSettings: [
                .define("LINUX", .when(platforms: [.linux])),
                .define("MACOS", .when(platforms: [.macOS]))
            ]),
        .testTarget(
            name: "WebResponseTests",
            dependencies: [
                "WebResponse",
                .product(name: "Swifter", package: "Swifter")
            ]
        )
    ]
)

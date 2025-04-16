// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWDCTools",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "WWDCFetch", targets: ["WWDCFetch"]),
        .library(name: "WWDCData", targets: ["WWDCData"]),
        .executable(name: "GetWWDC", targets: ["GetWWDC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cezheng/Fuzi", from: "3.1.3"),
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.58.2"),
        .package(url: "git@github.com:pointfreeco/sharing-grdb.git", from: "0.1.1"),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")
        ),
    ],
    targets: [
        .target(
            name: "WWDCData",
            dependencies: [
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ]
        ),
        .target(
            name: "WWDCFetch",
            dependencies: [
                .product(name: "Fuzi", package: "Fuzi"),
                .target(name: "WWDCData")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ]
        ),
        .executableTarget(
            name: "GetWWDC",
            dependencies: [
                .target(name: "WWDCData"),
                .target(name: "WWDCFetch"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ]
        ),
    ]
)

// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWDC 2023",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "WWDCFetch", targets: [
            "WWDCFetch",
        ]),
        .library(name: "WWDCData", targets: [
            "WWDCData",
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/cezheng/Fuzi", from: "3.1.3"),
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.58.2"),
        .package(url: "git@github.com:pointfreeco/sharing-grdb.git", from: "0.1.1"),
    ]
    , targets: [
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
    ]
)

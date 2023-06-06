// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWDC 2023",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "WWDCData", targets: [
            "WWDCData",
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/rnantes/swift-html-parser.git", branch: "master"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ]
    , targets: [
        .executableTarget(
            name: "GetWWDC",
            dependencies: [
                .byName(name: "WWDCData"),
                .product(name: "SwiftHTMLParser", package: "swift-html-parser"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .target(name: "WWDCData"),
    ]
)

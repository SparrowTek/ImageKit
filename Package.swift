// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ImageKit",
            targets: ["ImageKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SparrowTek/StorageKit.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "ImageKit",
            dependencies: [
                "StorageKit",
            ],
        ),
        .testTarget(
            name: "ImageKitTests",
            dependencies: ["ImageKit"]
        ),
    ]
)

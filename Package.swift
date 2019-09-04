// swift-tools-version:5.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Mothi",
    products: [
        .library(name: "Mothi", targets: ["Mothi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "Mothi", dependencies: ["NIO", "NIOHTTP1", "NIOFoundationCompat"]),
        .testTarget(name: "MothiTests", dependencies: ["Mothi"]),
        .target(name: "MothiExample", dependencies: ["Mothi"]),
    ]
)

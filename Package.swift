// swift-tools-version:5.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Mothi",
    products: [
        .library(name: "Mothi", targets: ["Mothi"]),
        .library(name: "Yggdrasil", targets: ["Yggdrasil"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "Mothi", dependencies: ["NIO", "NIOHTTP1", "NIOFoundationCompat", "Yggdrasil"]),
        .testTarget(name: "MothiTests", dependencies: ["Mothi"]),
        .target(name: "Yggdrasil", dependencies: []),
        .testTarget(name: "YggdrasilTests", dependencies: ["Yggdrasil"]),
        .target(name: "MothiExample", dependencies: ["Mothi"]),
        .testTarget(name: "MothiExampleTests", dependencies: ["MothiExample"]),
    ]
)

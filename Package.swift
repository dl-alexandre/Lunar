// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Lunar",
    targets: [
        .executableTarget(
            name: "Lunar"),
        .testTarget(
            name: "LunarTests",
            dependencies: ["Lunar"]
        )
    ]
)

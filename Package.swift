// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Kkhay",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "Kkhay",
            targets: ["Kkhay"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Kkhay",
            dependencies: []
        ),
        .testTarget(
            name: "KkhayTests",
            dependencies: ["Kkhay"]
        ),
    ]
)


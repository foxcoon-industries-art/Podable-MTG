// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Podr",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "Podr",
            targets: ["Podr"]
        ),
    ],
    dependencies: [
        .package(path: "../Podwork"),
        .package(path: "../Analypod")
    ],
    targets: [
        .target(
            name: "Podr",
            dependencies: ["Podwork", "Analypod"],
            path: "Podr",
            resources: [
            ]
        ),
    ]
)

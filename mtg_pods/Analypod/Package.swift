// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Analypod",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "Analypod",
            targets: ["Analypod"]
        ),
    ],
    dependencies: [
        .package(path: "../Podwork")
    ],
    targets: [
        .target(
            name: "Analypod",
            dependencies: ["Podwork"],
            path: "Analypod"
        ),
    ]
)

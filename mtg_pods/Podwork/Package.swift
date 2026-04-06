// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Podwork",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Podwork",
            targets: ["Podwork"]
        ),
    ],
    dependencies: [
        // No external dependencies to keep the framework lightweight
    ],
    targets: [
        .target(
            name: "Podwork",
            dependencies: [],
            path: "Podwork",
            resources: []
                //.process("file.json") // folder with your JSON file
            
        ),
    ]
)

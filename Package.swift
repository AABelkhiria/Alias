// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Alias",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Alias",
            targets: ["Alias"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Alias",
            dependencies: [],
            path: "Sources"
        )
    ]
)

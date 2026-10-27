// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TodoCore",
    // async/await y @MainActor necesitan estas versiones mínimas.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "TodoCore", targets: ["TodoCore"]),
    ],
    targets: [
        .target(name: "TodoCore"),
        .testTarget(name: "TodoCoreTests", dependencies: ["TodoCore"]),
    ]
)

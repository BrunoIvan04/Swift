// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TodoCore",
    products: [
        .library(name: "TodoCore", targets: ["TodoCore"]),
    ],
    targets: [
        .target(name: "TodoCore"),
        .testTarget(name: "TodoCoreTests", dependencies: ["TodoCore"]),
    ]
)

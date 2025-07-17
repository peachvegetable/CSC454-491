// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Peachy",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "PeachyApp",
            targets: ["PeachyApp"]
        ),
    ],
    dependencies: [
        // Add Realm dependency
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0"),
        // Add Lottie for animations
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.3.0"),
    ],
    targets: [
        .target(
            name: "PeachyApp",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "Sources/PeachyApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PeachyAppTests",
            dependencies: ["PeachyApp"],
            path: "Tests/PeachyAppTests"
        ),
    ]
)
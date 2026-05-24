// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Intentional",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Explicit dep because the Command Line Tools toolchain does not bundle
        // Swift Testing — only full Xcode does. Remove once Xcode is installed.
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "Intentional",
            path: "Sources/Intentional"
        ),
        .testTarget(
            name: "IntentionalTests",
            dependencies: [
                "Intentional",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/IntentionalTests"
        ),
    ]
)

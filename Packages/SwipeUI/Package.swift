// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "SwipeUI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "SwipeUI", targets: ["SwipeUI"])],
    dependencies: [],
    targets: [
        .target(name: "SwipeUI", dependencies: []),
        .testTarget(name: "SwipeUITests", dependencies: ["SwipeUI"]),
    ]
)

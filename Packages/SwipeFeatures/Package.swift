// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "SwipeFeatures",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "SwipeFeatures", targets: ["SwipeFeatures"])],
    dependencies: [.package(path: "../SwipeUI"), .package(path: "../SwipeCore")],
    targets: [
        .target(name: "SwipeFeatures", dependencies: [.product(name: "SwipeUI", package: "SwipeUI"), .product(name: "SwipeCore", package: "SwipeCore")]),
        .testTarget(name: "SwipeFeaturesTests", dependencies: ["SwipeFeatures"]),
    ]
)

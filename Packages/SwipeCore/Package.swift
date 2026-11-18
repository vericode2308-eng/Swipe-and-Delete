// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "SwipeCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "SwipeCore", targets: ["SwipeCore"])],
    
    targets: [
        .target(name: "SwipeCore", dependencies: []),
        .testTarget(name: "SwipeCoreTests", dependencies: ["SwipeCore"]),
    ]
)

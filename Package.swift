// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "TaskFire", platforms: [.macOS(.v14)], products: [.executable(name: "TaskFire", targets: ["TaskFire"])], targets: [.target(name: "TaskFireCore"), .executableTarget(name: "TaskFire", dependencies: ["TaskFireCore"]), .testTarget(name: "TaskFireCoreTests", dependencies: ["TaskFireCore"])])

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipPilot",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipPilot",
            targets: ["ClipPilot"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClipPilot",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ClipPilotTests",
            dependencies: ["ClipPilot"],
            path: "Tests/ClipPilotTests"
        )
    ]
)

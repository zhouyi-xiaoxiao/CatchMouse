// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CatchMouse",
    platforms: [.macOS(.v11)],
    targets: [
        .executableTarget(
            name: "CatchMouse",
            path: "Sources/CatchMouse",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ColorSync")
            ]
        )
    ]
)

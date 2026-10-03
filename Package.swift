// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FixMyADHD",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FixMyADHD",
            path: "Sources/FixMyADHD"
        )
    ]
)

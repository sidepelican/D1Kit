// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "D1Kit",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [
        .library(name: "D1Kit", targets: ["D1Kit"]),
        .library(name: "D1KitFoundation", targets: ["D1KitFoundation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "D1Kit",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .target(
            name: "D1KitFoundation",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                "D1Kit",
            ]
        ),
        .testTarget(
            name: "D1KitTests",
            dependencies: [
                "D1Kit",
                "D1KitFoundation",
            ]
        ),
    ]
)

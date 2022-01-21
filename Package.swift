// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkLayer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "NetworkLayer",
            targets: ["NetworkLayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.2.2")
    ],
    targets: [
        .target(
            name: "NetworkLayer",
            dependencies: ["Alamofire"]
        )
    ]
)

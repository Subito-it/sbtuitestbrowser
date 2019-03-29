// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sbtuitestbrowser",
    dependencies: [
      .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
    ],
    targets: [
      .target(
          name: "sbtuitestbrowser",
          dependencies: ["PerfectHTTPServer"])
    ]
)

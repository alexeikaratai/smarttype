// swift-tools-version: 6.2

import PackageDescription

/// Applied to every target so the whole package moves together.
///
/// The upcoming features are slated to become defaults; enabling them now means the
/// migration is already done and cannot regress. Warnings are errors so nothing quietly
/// accumulates — except deprecations, so a new SDK cannot break the build overnight.
let strict: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .treatAllWarnings(as: .error),
    .treatWarning("DeprecatedDeclaration", as: .warning),
]

/// AppKit, Carbon and the pasteboard are main-thread APIs, so the shell defaults to the main actor.
let mainActorShell: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "SmartType",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // Pure decision logic: layouts, conversion, language detection, correction.
        // Foundation only, no isolation, strict memory safety.
        .target(
            name: "SmartTypeCore",
            path: "Sources/SmartTypeCore",
            swiftSettings: strict + [.strictMemorySafety()]
        ),
        // The AppKit shell as a library, so the test bundle can build a menu and read it back.
        // The executable keeps only `main.swift`.
        .target(
            name: "SmartTypeApp",
            path: "Sources/SmartTypeApp",
            swiftSettings: strict + mainActorShell
        ),
        .executableTarget(
            name: "SmartType",
            dependencies: ["SmartTypeApp"],
            path: "Sources/SmartType",
            swiftSettings: strict + mainActorShell
        ),
        .testTarget(
            name: "SmartTypeCoreTests",
            dependencies: ["SmartTypeCore"],
            path: "Tests/SmartTypeCoreTests",
            swiftSettings: strict
        ),
        .testTarget(
            name: "SmartTypeAppTests",
            dependencies: ["SmartTypeApp", "SmartTypeCore"],
            path: "Tests/SmartTypeAppTests",
            swiftSettings: strict + mainActorShell
        ),
    ]
)

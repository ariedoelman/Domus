import PackageDescription

let package = Package(
    name: "Domus",
    dependencies: [
      .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 3),
      .Package(url: "https://github.com/ariedoelman/GrovePiIO.git", majorVersion: 1, minor: 2)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
        "Tests",
    ]
)


import BuildSystem

public struct DocbookXsl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.79.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/c-ares/c-ares/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://c-ares.haxx.se/download/c-ares-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ],
      products: [
        .bin("acountry"),
        .bin("adig"),
        .bin("ahost"),
        .library(
          name: "libcares",
          headers: [
            "ares_build.h", "ares_dns.h",
            "ares_rules.h", "ares_version.h",
            "ares.h"
          ]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildStatic, "CARES_STATIC", defaultEnabled: false),
        cmakeOnFlag(env.libraryType.buildShared, "CARES_SHARED", defaultEnabled: true),
        cmakeOnFlag(env.isBuildingCross, "CARES_STATIC_PIC", defaultEnabled: false)
      )

      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }
  }

}

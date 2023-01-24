import BuildSystem

public struct CAres: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.18.1"
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

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildStatic, "CARES_STATIC"),
        cmakeOnFlag(context.libraryType.buildShared, "CARES_SHARED"),
        cmakeOnFlag(context.isBuildingCross, "CARES_STATIC_PIC")
      )

      try context.make(toolType: .ninja)

      try context.make(toolType: .ninja, "install")
    }
  }

}

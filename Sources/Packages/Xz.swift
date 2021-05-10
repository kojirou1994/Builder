import BuildSystem

public struct Xz: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.2.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/lzmautils/xz-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      products: [
        .bin("xzdec"),
        .bin("lzmadec"),
        .bin("lzmainfo"),
        .bin("xz"),
        .library(name: "lzma", headers: ["lzma", "lzma.h"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    if env.canRunTests {
      try env.make("check")
    }
    try env.make("install")
  }

}

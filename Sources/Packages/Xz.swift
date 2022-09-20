import BuildSystem

public struct Xz: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.2.6"
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

  public func build(with context: BuildContext) throws {

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }

}

import BuildSystem

public struct Gmp: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "6.3.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.arch {
    case .armv7, .armv7k, .armv7s, .arm64_32:
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/gmp/gmp-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(M4.self)
      ],
      products: [
        .library(name: "gmp", headers: ["gmp.h"]),
        .library(name: "gmpxx", headers: ["gmpxx.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(true, "cxx"),
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

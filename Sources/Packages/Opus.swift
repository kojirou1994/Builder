import BuildSystem

public struct Opus: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let includeZeroPatch: Bool
      if version < "1.1" {
        includeZeroPatch = true
      } else {
        includeZeroPatch = false
      }
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-\(version.toString(includeZeroPatch: includeZeroPatch)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ]),
      products: [.library(name: "libopus", headers: ["opus"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "custom-modes"),
      configureEnableFlag(false, "doc")
    )

    try env.make()
    try env.make("install")
  }

}

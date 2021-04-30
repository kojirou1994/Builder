import BuildSystem

public struct Ogg: Package {

  public init() {}
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  public var defaultVersion: PackageVersion {
    "1.3.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macCatalyst:
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [.library(name: "libogg", headers: ["ogg"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make(parallelJobs: 1, "install")
  }

}

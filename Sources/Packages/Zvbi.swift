import BuildSystem

public struct Zvbi: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.2.35"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS, .linuxGNU:
      break
    default: throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://nchc.dl.sourceforge.net/project/zapping/zvbi/\(versionString)/zvbi-\(versionString).tar.bz2")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      nil
    )

    try env.make()

    try env.make("install")
  }

}

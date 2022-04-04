import BuildSystem

public struct Smartmontools: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "7.3.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.system {
    case .macOS, .macCatalyst, .linuxGNU:
      break
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://downloads.sourceforge.net/project/smartmontools/smartmontools/\(versionString)/smartmontools-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(true, "sample"),
      configureWithFlag(true, "savestates"),
      configureWithFlag(true, "attributelog")
    )

    try context.make()
    try context.make("install")
  }
}

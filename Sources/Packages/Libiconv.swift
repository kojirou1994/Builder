import BuildSystem

public struct Libiconv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.16.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
//        .runTime(Gettext.self),
      ]
    )
  }

  public func build(with env: BuildContext) throws {

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "extra-encodings")
//      configureWithFlag(env.dependencyMap[Gettext.self], "libintl-prefix")
    )

    try env.make()
    try env.make("install")
  }
}

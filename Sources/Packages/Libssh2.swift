import BuildSystem

public struct Libssh2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.9.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://libssh2.org/download/libssh2-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Zlib.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.launch(path: "buildconf")

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "examples-build")
//      configureWithFlag(context.dependencyMap[Openssl.self], "libssl-prefix")
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }
}

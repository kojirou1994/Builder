import BuildSystem

public struct Pcre2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "10.36"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.pcre.org/pub/pcre/pcre2-\(version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "pcre2-16"),
      configureEnableFlag(true, "pcre2-32"),
      configureEnableFlag(true, "pcre2grep-libz"),
      configureEnableFlag(true, "pcre2grep-libbz2")
      //configureEnableFlag(true, "jit") // not for apple silicon
    )

    try env.make()
    try env.make("install")
  }

}

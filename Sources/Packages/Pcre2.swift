import BuildSystem

public struct Pcre2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "10.45.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let str = version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)
      source = .tarball(url: "https://github.com/PhilipHazel/pcre2/releases/download/pcre2-\(str)/pcre2-\(str).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()
    
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "pcre2-16"),
      configureEnableFlag(true, "pcre2-32"),
      configureEnableFlag(true, "pcre2grep-libz"),
      configureEnableFlag(true, "pcre2grep-libbz2")
      //configureEnableFlag(true, "jit") // not for apple silicon
    )

    try context.make()
    try context.make("install")
  }

}

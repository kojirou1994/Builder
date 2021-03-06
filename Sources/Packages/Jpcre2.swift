import BuildSystem

public struct Jpcre2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "10.32.01"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/jpcre2/jpcre2/archive/refs/tags/\(version.toString(numberWidth: 2)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(Pcre2.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }

}

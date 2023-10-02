import BuildSystem

public struct Isl: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "0.26"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://libisl.sourceforge.io/isl-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(Gmp.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()
    
    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      "--with-gmp-prefix=\(context.dependencyMap[Gmp.self])"
    )

    try context.make()
    try context.make("install")
  }
}

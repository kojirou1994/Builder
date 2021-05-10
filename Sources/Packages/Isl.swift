import BuildSystem

public struct Isl: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "0.23"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://isl.gforge.inria.fr/isl-\(version.toString(includeZeroPatch: false)).tar.xz")
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

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-gmp-prefix=\(env.dependencyMap[Gmp.self])"
    )

    try env.make()
    try env.make("install")
  }
}

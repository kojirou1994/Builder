import BuildSystem

public struct Aribb24: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/nkoriyama/aribb24/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Png.self),
      ])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    env.environment["PNG_CFLAGS"] = env.dependencyMap[Png.self].cflag
    env.environment["PNG_LIBS"] = env.dependencyMap[Png.self].ldflag
    env.environment.append("-lpng16", for: "PNG_LIBS")
    if env.libraryType.buildStatic {
      env.environment.append("-lz", for: "PNG_LIBS")
    }

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}

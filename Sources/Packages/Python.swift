import BuildSystem

public struct Python: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.9.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://www.python.org/ftp/python/\(version)/Python-\(version).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Xz.self),
        .runTime(Bzip2.self),
//        .runTime(Gdbm.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure(
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "optimizations"),
//      configureWithFlag(true, "lto"),
      configureEnableFlag(true, "ipv6"),
//      configureEnableFlag(true, "loadable-sqlite-extensions")
//      configureWithFlag(context.dependencyMap[Openssl.self], "openssl"),
      nil
    )

    try context.make()

//    if context.canRunTests {
//      try context.make("test")
//    }

    try context.make("install")
  }

}

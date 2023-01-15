import BuildSystem

public struct Gcrypt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.10.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(GpgError.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      "--with-gpg-error-prefix=\(context.dependencyMap[GpgError.self].root.path)",
      configureEnableFlag(!context.order.system.isApple, "asm")
    )

    try context.make()
    try context.make("install")
  }

}

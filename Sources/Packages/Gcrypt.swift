import BuildSystem

public struct Gcrypt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    // 1.10.2 failed to build: https://dev.gnupg.org/T6442
    "1.10.3"
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

    // TODO: edit random/Makefile
    // change CCASFLAGS and CFLAGS to -O0
    // call make rndjent.lo rndjent.o

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureWithFlag(context.dependencyMap[GpgError.self].root.path, "gpg-error-prefix"),
      configureEnableFlag(!context.order.system.isApple, "asm")
    )

    try context.make()
    try context.make("install")
  }

}

import BuildSystem

public struct GpgError: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.48.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-\(version.toString(includeZeroPatch: false)).tar.bz2")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {

    /*
     make gcrypt happy:
     https://dev.gnupg.org/T6257
     */
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      context.order.version >= "1.46" ? configureEnableFlag(true, "install-gpg-error-config") : nil
    )

    try context.make()
    try context.make("install")
  }

}

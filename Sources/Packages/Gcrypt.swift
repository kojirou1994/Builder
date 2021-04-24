import BuildSystem

public struct Gcrypt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.8.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS:
      break
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(packages: .runTime(GpgError.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-gpg-error-prefix=\(env.dependencyMap[GpgError.self].root.path)",
      configureEnableFlag(env.isBuildingNative, "asm", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

}

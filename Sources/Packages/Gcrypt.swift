import BuildSystem

public struct Gcrypt: Package {
  public init() {}
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

  public var defaultVersion: PackageVersion {
    .stable("1.8.7")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-\(version.toString()).tar.bz2")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(GpgError.self))
  }

  public func supports(target: BuildTriple) -> Bool {
    switch target.system {
    case .macOS:
      return true
    default:
      return false
    }
  }
}

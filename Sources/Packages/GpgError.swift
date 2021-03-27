import BuildSystem

public struct GpgError: Package {
  public init() {}
  public func build(with env: BuildEnvironment) throws {
    //    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  public var defaultVersion: PackageVersion {
    .stable("1.42")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-\(version.toString(includeZeroPatch: false)).tar.bz2")
  }

}

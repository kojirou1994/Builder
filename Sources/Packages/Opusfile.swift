import BuildSystem

public struct Opusfile: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.12")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opusfile-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking)
    )
    try env.make("install")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Openssl.self), .init(Opus.self), .init(Ogg.self))
  }

}

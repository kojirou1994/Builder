import BuildSystem

public struct Opusenc: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.2.1")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/libopusenc-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    
    try env.make()
    try env.make("install")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Opus.self))
  }

}

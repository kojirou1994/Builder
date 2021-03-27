import BuildSystem

public struct OpusTools: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.2")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-tools-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    try env.make("install")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Flac.self),
      .init(Ogg.self),
      .init(Opus.self),
      .init(Opusenc.self),
      .init(Opusfile.self)
    )
  }

}

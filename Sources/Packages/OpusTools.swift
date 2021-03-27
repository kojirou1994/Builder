import BuildSystem

struct OpusTools: Package {

  var defaultVersion: PackageVersion {
    .stable("0.2")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-tools-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    try env.make("install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Flac.self),
      .init(Ogg.self),
      .init(Opus.self),
      .init(Opusenc.self),
      .init(Opusfile.self)
    )
  }

}

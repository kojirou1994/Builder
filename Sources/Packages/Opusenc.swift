import BuildSystem

struct Opusenc: Package {

  var defaultVersion: PackageVersion {
    .stable("0.2.1")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/libopusenc-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    
    try env.make()
    try env.make("install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Opus.self))
  }

}

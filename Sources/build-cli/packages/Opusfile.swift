import BuildSystem

struct Opusfile: Package {

  var defaultVersion: PackageVersion {
    .stable("0.12")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opusfile-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking)
    )
    try env.make("install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Openssl.self), .init(Opus.self), .init(Ogg.self))
  }

}

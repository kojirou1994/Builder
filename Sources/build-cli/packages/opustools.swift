import BuildSystem

struct OpusTools: Package {

  var source: PackageSource {
    packageSource(for: version)!
  }

  var version: PackageVersion {
    .stable("0.2")
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://archive.mozilla.org/pub/opus/opus-tools-\(v).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    try env.make("install")
  }

  var dependencies: PackageDependency {
    .packages(
      Flac.defaultPackage,
      Ogg.defaultPackage,
      Opus.defaultPackage,
      Opusenc.defaultPackage,
      OpusFile.defaultPackage
    )
  }

}

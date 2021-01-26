import BuildSystem

struct Opusenc: Package {

  var source: PackageSource {
    packageSource(for: version)!
  }

  var version: PackageVersion {
    .stable("0.2.1")
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://archive.mozilla.org/pub/opus/libopusenc-\(v).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking)
    )
    
    try env.make()
    try env.make("install")
  }

  var dependencies: PackageDependency {
    .packages(Opus.defaultPackage())
  }

}

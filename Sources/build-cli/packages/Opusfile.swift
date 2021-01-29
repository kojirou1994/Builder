import BuildSystem

struct Opusfile: Package {

  var source: PackageSource {
    packageSource(for: version)!
  }

  var version: PackageVersion {
    .stable("0.12")
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://downloads.xiph.org/releases/opus/opusfile-\(v).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking)
    )
    try env.make("install")
  }

  var dependencies: PackageDependency {
    .packages(Openssl.defaultPackage, Opus.defaultPackage, Ogg.defaultPackage)
  }

}

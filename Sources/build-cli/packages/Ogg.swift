import BuildSystem

struct Ogg: Package {
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  var version: PackageVersion {
    .stable("1.3.3")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(v).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}

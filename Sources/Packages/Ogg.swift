import BuildSystem

struct Ogg: Package {
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  var defaultVersion: PackageVersion {
    .stable("1.3.3")
  }

  var products: [BuildProduct] {
    [.library(name: "libogg", headers: ["ogg"])]
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(version.toString()).tar.gz")
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

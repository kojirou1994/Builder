import BuildSystem

struct Xml2: Package {
  var defaultVersion: PackageVersion {
    .stable("2.9.10")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      "--without-lzma"
    )

    try env.make()

    try env.make("install")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "http://xmlsoft.org/sources/libxml2-\(version.toString()).tar.gz")
  }
}

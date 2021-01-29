import BuildSystem

struct Xml2: Package {
  var version: PackageVersion {
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

  var source: PackageSource {
    .tarball(url: "http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz")
  }
}

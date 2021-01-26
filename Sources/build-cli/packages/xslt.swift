import BuildSystem

struct Xslt: Package {
//  var version: PackageVersion {
//    .stable("2.9.10")
//  }

  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      nil
    )

    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz")
  }

  var dependencies: PackageDependency {
    .packages(Xml2.defaultPackage(), Gcrypt.defaultPackage())
  }
}

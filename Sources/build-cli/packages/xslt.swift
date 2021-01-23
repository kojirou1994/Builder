import BuildSystem

struct Xslt: Package {
//  var version: PackageVersion {
//    .stable("2.9.10")
//  }

  func build(with builder: Builder) throws {
    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      "--without-python",
      nil
    )

    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz")
  }

  var dependencies: [Package] {
    [Xml2.defaultPackage(), Gcrypt.defaultPackage()]
  }
}

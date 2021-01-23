import BuildSystem

struct Xml2: Package {
  var version: PackageVersion {
    .stable("2.9.10")
  }

  func build(with builder: Builder) throws {
    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      "--without-python",
      "--without-lzma"
    )

    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz")
  }
}

import BuildSystem

struct Jpcre2: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/jpcre2/jpcre2/archive/10.32.01.tar.gz", filename: "jpcre2-10.32.01.tar.gz")
  }
  var version: PackageVersion {
    .stable("10.32.01")
  }
  var dependencies: [Package] {
    [Pcre2.defaultPackage()]
  }
}

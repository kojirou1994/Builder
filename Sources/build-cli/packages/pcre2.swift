import BuildSystem

struct Pcre2: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      configureFlag(true, "pcre2-16"),
      configureFlag(true, "pcre2-32"),
      configureFlag(true, "pcre2grep-libz"),
      configureFlag(true, "pcre2grep-libbz2")
      //configureFlag(true, "jit") // not for apple silicon
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://ftp.pcre.org/pub/pcre/pcre2-10.36.tar.bz2")
  }
  var version: PackageVersion {
    .stable("10.36")
  }
}

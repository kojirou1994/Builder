import BuildSystem

struct Pcre2: Package {
  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "pcre2-16"),
      configureEnableFlag(true, "pcre2-32"),
      configureEnableFlag(true, "pcre2grep-libz"),
      configureEnableFlag(true, "pcre2grep-libbz2")
      //configureEnableFlag(true, "jit") // not for apple silicon
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://ftp.pcre.org/pub/pcre/pcre2-10.36.tar.bz2")
  }
  var version: PackageVersion {
    .stable("10.36")
  }
}

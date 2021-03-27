import BuildSystem

struct Pcre2: Package {

  var defaultVersion: PackageVersion {
    .stable("10.36")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.pcre.org/pub/pcre/pcre2-\(version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)).tar.bz2")
  }

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

}

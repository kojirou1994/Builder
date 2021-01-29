import BuildSystem

struct Jpcre2: Package {
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

  var source: PackageSource {
    .tarball(url: "https://github.com/jpcre2/jpcre2/archive/10.32.01.tar.gz", filename: "jpcre2-10.32.01.tar.gz")
  }
  var version: PackageVersion {
    .stable("10.32.01")
  }
  var dependencies: PackageDependency {
    .packages(Pcre2.defaultPackage)
  }
}

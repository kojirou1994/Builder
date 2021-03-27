import BuildSystem

struct Jpcre2: Package {
  var defaultVersion: PackageVersion {
    .stable("10.32.01")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/jpcre2/jpcre2/archive/refs/tags/\(version.toString(numberWidth: 2)).tar.gz")
  }

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

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Pcre2.self))
  }
}

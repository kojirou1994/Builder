import BuildSystem

struct Xslt: Package {
  var defaultVersion: PackageVersion {
    .stable("1.1.34")
  }

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

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "http://xmlsoft.org/sources/libxslt-\(version.toString()).tar.gz")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Xml2.self), .init(Gcrypt.self))
  }
}

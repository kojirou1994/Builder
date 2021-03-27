import BuildSystem

public struct Xml2: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("2.9.10")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      "--without-lzma"
    )

    try env.make()

    try env.make("install")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "http://xmlsoft.org/sources/libxml2-\(version.toString()).tar.gz")
  }
}

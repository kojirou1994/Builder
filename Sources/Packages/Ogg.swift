import BuildSystem

public struct Ogg: Package {
  public init() {}
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  public var defaultVersion: PackageVersion {
    .stable("1.3.3")
  }

  public var products: [BuildProduct] {
    [.library(name: "libogg", headers: ["ogg"])]
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}

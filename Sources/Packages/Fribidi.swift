import BuildSystem

public struct Fribidi: Package {
  public init() {}
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

  public var defaultVersion: PackageVersion {
    .stable("1.0.10")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/fribidi/fribidi/archive/refs/tags/v\(version.toString()).tar.gz")
  }
}

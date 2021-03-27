import BuildSystem

public struct Xz: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("5.2.5")
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make("check")
    try env.make("install")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.sourceforge.net/project/lzmautils/xz-\(version.toString()).tar.gz")
  }
}

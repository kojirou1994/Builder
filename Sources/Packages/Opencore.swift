import BuildSystem

public struct Opencore: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.1.5")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://deac-riga.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-\(version).tar.gz")
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

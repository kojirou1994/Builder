import BuildSystem

public struct FdkAac: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.0.1")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-\(version).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(example, "example")
    )
    try env.make("install")
  }
  
  @Flag(inversion: .prefixedEnableDisable, help: "Enable example encoding program.")
  var example: Bool = false

}

import BuildSystem

public struct Sdl2: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.0.14")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://libsdl.org/release/SDL2-\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(false, "doc")
    )
    try env.make("install")
  }

}

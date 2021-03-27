import BuildSystem

public struct Aribb24: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.0.3")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/nkoriyama/aribb24/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "bootstrap")
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Png.self))
  }
}

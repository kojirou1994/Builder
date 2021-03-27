import BuildSystem

public struct Freetype: Package {
  public init() {}
  public func build(with env: BuildEnvironment) throws {

    try env.launch(path: "autogen.sh")

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--enable-freetype-config",
      "--without-harfbuzz",
      "--without-brotli"
    )

    try env.make()
    try env.make("install")
  }

  public var defaultVersion: PackageVersion {
    .stable("2.10.4")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    let versionString = version.toString(includeZeroPatch: false)
    return .tarball(url: "https://downloads.sourceforge.net/project/freetype/freetype2/\(versionString)/freetype-\(versionString).tar.xz")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Png.self))
  }
}

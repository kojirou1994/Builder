import BuildSystem

public struct Fribidi: Package {
  public init() {}
  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.meson(
        "..",
        "--default-library=\(env.libraryType.mesonFlag)"
      )

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }

  public var defaultVersion: PackageVersion {
    .stable("1.0.10")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/fribidi/fribidi/releases/download/v\(version.toString())/fribidi-\(version.toString(includeZeroPatch: false)).tar.xz")
  }
}

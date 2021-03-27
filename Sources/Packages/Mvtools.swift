import BuildSystem

public struct Mvtools: Package {
  public init() {}

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.meson("..")

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }
}

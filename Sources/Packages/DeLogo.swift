import BuildSystem

public struct DeLogo: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.4")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DeLogo/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DeLogo/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch("chmod", "+x", "configure")
    try env.launch(path: "./configure", "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)")

    try env.make()
    try env.make("install")
  }
}

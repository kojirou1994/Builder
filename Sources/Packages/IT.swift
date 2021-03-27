import BuildSystem

public struct IT: Package {
  public init() {}

  #if os(macOS)
  public var defaultVersion: PackageVersion {
    .stable("1.2")
  }
  #endif

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-IT/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-IT/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch("chmod", "+x", "configure")
    try env.launch(path: "./configure", "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)")

    try env.make()
    try env.make("install")
  }
}

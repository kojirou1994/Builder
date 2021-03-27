import BuildSystem

public struct Bilateral: Package {
  public init() {}

  #if !os(macOS)
  public var defaultVersion: PackageVersion {
    .stable("3")
  }
  #endif

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-Bilateral/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-Bilateral/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch("chmod", "+x", "configure")
    try env.launch(path: "./configure", "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)")

    try env.make()
    try env.make("install")
  }
}

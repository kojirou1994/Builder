import BuildSystem

public struct Eedi3: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("4")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  /*
   Requires Boost unless specify -Dopencl=false.
   */
  public func build(with env: BuildEnvironment) throws {
    try replace(contentIn: "meson.build",
                matching: "join_paths(vapoursynth_dep.get_pkgconfig_variable('libdir'), 'vapoursynth')",
                with: "join_paths(get_option('prefix'), get_option('libdir'), 'vapoursynth')")

    try env.changingDirectory("build", block: { _ in
      try env.meson("..")

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }
}

import BuildSystem

struct FFT3DFilter: Package {

//  var defaultVersion: PackageVersion {
//    .stable("1")
//  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/kojirou1994/VapourSynth-FFT3DFilter/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/kojirou1994/VapourSynth-FFT3DFilter/archive/refs/tags/R\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
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

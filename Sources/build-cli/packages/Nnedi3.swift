import BuildSystem

struct Nnedi3: Package {

  var defaultVersion: PackageVersion {
    .stable("12")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  /*
   The file nnedi3_weights.bin is required. In Windows, it must be located in the same folder as libnnedi3.dll. Everywhere else it can be located either in the same folder as libnnedi3.so/libnnedi3.dylib, or in $prefix/share/nnedi3/. The build system installs it at the latter location automatically.
   */
  func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure()

    try env.make()
    try env.make("install")
  }
}

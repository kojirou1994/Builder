import BuildSystem

public struct Nnedi3: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("12")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  /*
   The file nnedi3_weights.bin is required. In Windows, it must be located in the same folder as libnnedi3.dll. Everywhere else it can be located either in the same folder as libnnedi3.so/libnnedi3.dylib, or in $prefix/share/nnedi3/. The build system installs it at the latter location automatically.
   */
  public func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure()

    try env.make()
    try env.make("install")
  }
}

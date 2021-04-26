import BuildSystem

public struct Nnedi3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source
    )
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

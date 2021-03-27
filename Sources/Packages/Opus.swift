import BuildSystem

public struct Opus: Package {
  public init() {}

  public static var name: String { "opus" }

  public var defaultVersion: PackageVersion {
    .stable("1.3.1")
  }

  public var products: [BuildProduct] {
    [BuildProduct.library(name: "libopus", headers: ["opus"])]
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    let includeZeroPatch: Bool
    if version < "1.1" {
      includeZeroPatch = true
    } else {
      includeZeroPatch = false
    }
    return .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-\(version.toString(includeZeroPatch: includeZeroPatch)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "doc")
    )

    try env.make()

    try env.make("install")
  }

}

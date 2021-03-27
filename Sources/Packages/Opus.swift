import BuildSystem

struct Opus: Package {

  static var name: String { "opus" }

  var defaultVersion: PackageVersion {
    .stable("1.3.1")
  }

  var products: [BuildProduct] {
    [BuildProduct.library(name: "libopus", headers: ["opus"])]
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    let includeZeroPatch: Bool
    if version < "1.1" {
      includeZeroPatch = true
    } else {
      includeZeroPatch = false
    }
    return .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-\(version.toString(includeZeroPatch: includeZeroPatch)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
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

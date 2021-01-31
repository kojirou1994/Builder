import BuildSystem

struct Opus: Package {

  static var name: String { "opus" }

  var version: PackageVersion {
    .stable("1.3.1")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  var products: [BuildProduct] {
    [BuildProduct.library(name: "libopus", headers: ["opus"])]
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://archive.mozilla.org/pub/opus/opus-\(v).tar.gz")
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

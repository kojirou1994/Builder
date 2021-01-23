import BuildSystem

struct Opus: Package {
  func build(with builder: Builder) throws {
    try builder.configure(
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared"),
      false.configureFlag("dependency-tracking"),
      false.configureFlag("doc")
    )
    try builder.make("install")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  var version: PackageVersion {
    .stable("1.3.1")
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://archive.mozilla.org/pub/opus/opus-\(v).tar.gz")
  }
}

import BuildSystem

struct Opencore: Package {

  var version: PackageVersion {
    .stable("0.1.5")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://deac-riga.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-\(v).tar.gz")
  }
  func build(with builder: Builder) throws {

    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared")
    )

    try builder.make("install")
  }

}

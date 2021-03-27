import BuildSystem

struct Ass: Package {
  var defaultVersion: PackageVersion {
    .stable("0.15.0")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/libass/libass/archive/refs/tags/\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "fontconfig")
    )

    try env.make()
    try env.make("install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Freetype.self),
      .init(Harfbuzz.self),
      .init(Fribidi.self)
    )
  }
}

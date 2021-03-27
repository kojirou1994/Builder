import BuildSystem

struct Xz: Package {
  var defaultVersion: PackageVersion {
    .stable("5.2.5")
  }

  func build(with env: BuildEnvironment) throws {

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make("check")
    try env.make("install")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.sourceforge.net/project/lzmautils/xz-\(version.toString()).tar.gz")
  }
}

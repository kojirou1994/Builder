import BuildSystem

struct Xz: Package {
  var version: PackageVersion {
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

  var source: PackageSource {
    .tarball(url: "https://downloads.sourceforge.net/project/lzmautils/xz-5.2.5.tar.gz")
  }
}

import BuildSystem

struct Zvbi: Package {

  var version: PackageVersion {
    .stable("0.2.35")
  }

  var source: PackageSource {
    .tarball(url: "https://raw.githubusercontent.com/cntrump/build_ffmpeg_brew/master/zvbi-0.2.35.tar.bz2")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      nil
    )

    try env.make()

    try env.make("install")
  }

}

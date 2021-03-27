import BuildSystem

struct Lame: Package {
  func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "include/libmp3lame.sym", matching: "lame_init_old\n", with: "")

//    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(env.isBuildingNative, "nasm"),
      configureEnableFlag(false, "frontend")
    )

    try env.make("install")
  }

  var defaultVersion: PackageVersion {
    .stable("3.100")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    let versionString = version.toString(includeZeroPatch: false)
    return .tarball(url: "https://nchc.dl.sourceforge.net/project/lame/lame/\(versionString)/lame-\(versionString).tar.gz")
  }

}

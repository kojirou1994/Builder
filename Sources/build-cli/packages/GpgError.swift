import BuildSystem

struct GpgError: Package {
  func build(with env: BuildEnvironment) throws {
    //    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.41.tar.bz2")
  }

  var version: PackageVersion {
    .stable("1.41")
  }

}

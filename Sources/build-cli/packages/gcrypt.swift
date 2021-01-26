import BuildSystem

struct Gcrypt: Package {
  func build(with env: BuildEnvironment) throws {
//    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
//      configureEnableFlag(false, "fontconfig")
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.7.tar.bz2")
  }

  var dependencies: PackageDependency {
    .packages(GpgError.defaultPackage())
  }
}

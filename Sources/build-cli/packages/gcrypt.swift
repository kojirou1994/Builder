import BuildSystem

struct Gcrypt: Package {
  func build(with builder: Builder) throws {
//    try builder.autoreconf()
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
//      configureFlag(false, "fontconfig")
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.7.tar.bz2")
  }

  var dependencies: [Package] {
    [GpgError.defaultPackage()]
  }
}

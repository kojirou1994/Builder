import BuildSystem

struct GpgError: Package {
  func build(with builder: Builder) throws {
    //    try builder.autoreconf()
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.41.tar.bz2")
  }

}

import BuildSystem

struct Xz: Package {
  var version: PackageVersion {
    .stable("5.2.5")
  }

  func build(with builder: Builder) throws {

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make("check")
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.sourceforge.net/project/lzmautils/xz-5.2.5.tar.gz")
  }
}

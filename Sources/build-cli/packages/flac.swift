import BuildSystem

struct Flac: Package {
  var version: PackageVersion {
    .stable("1.3.3")
  }

  func build(with builder: Builder) throws {
    try builder.launch(path: "autogen.sh")
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.xiph.org/releases/flac/flac-1.3.3.tar.xz")
  }

  var dependencies: [Package] {
    [Ogg.defaultPackage()]
  }
}

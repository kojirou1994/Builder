import BuildSystem

struct Icu4c: Package {
  var version: PackageVersion {
    .stable("67.1")
  }

  func build(with builder: Builder) throws {
    try builder.changingDirectory("source", block: { _ in
      try builder.autoreconf()

      try builder.configure(
        //      false.configureFlag(CommonOptions.dependencyTracking),
        builder.settings.library.staticConfigureFlag,
        builder.settings.library.sharedConfigureFlag,
        "--disable-samples",
        "--disable-tests",
        "--with-library-bits=64"
      )

      try builder.make()
      try builder.make("install")
    })
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/unicode-org/icu/releases/download/release-67-1/icu4c-67_1-src.tgz", filename: "icu.tgz")
  }
}

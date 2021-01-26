import BuildSystem

struct Icu4c: Package {
  var version: PackageVersion {
    .stable("67.1")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("source", block: { _ in
      try env.autoreconf()

      try env.configure(
        //      configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        "--disable-samples",
        "--disable-tests",
        "--with-library-bits=64"
      )

      try env.make()
      try env.make("install")
    })
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/unicode-org/icu/releases/download/release-67-1/icu4c-67_1-src.tgz", filename: "icu.tgz")
  }
}

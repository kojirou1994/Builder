import BuildSystem

struct Icu4c: Package {
  var defaultVersion: PackageVersion {
    .stable("68.2")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/unicode-org/icu/archive/refs/tags/release-\(version.toString(includeZeroMinor: false, includeZeroPatch: false, versionSeparator: "-")).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("icu4c/source", block: { _ in
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

}

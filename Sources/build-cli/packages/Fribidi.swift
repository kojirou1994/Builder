import BuildSystem

struct Fribidi: Package {
  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/fribidi/fribidi/releases/download/v1.0.10/fribidi-1.0.10.tar.xz")
  }
}

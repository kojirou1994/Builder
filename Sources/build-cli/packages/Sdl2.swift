import BuildSystem

struct Sdl2: Package {
  func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(false, "doc")
    )
    try env.make("install")
  }

  var version: PackageVersion {
    .stable("2.0.14")
  }

  var source: PackageSource {
    .tarball(url: "https://libsdl.org/release/SDL2-2.0.14.tar.gz")
  }
}

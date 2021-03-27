import BuildSystem

struct Sdl2: Package {

  var defaultVersion: PackageVersion {
    .stable("2.0.14")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://libsdl.org/release/SDL2-\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(false, "doc")
    )
    try env.make("install")
  }

}

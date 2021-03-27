import BuildSystem

struct Png: Package {
  var defaultVersion: PackageVersion {
    .stable("1.6.37")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.sourceforge.net/project/libpng/libpng16/\(version)/libpng-\(version.toString()).tar.xz")
  }

  func build(with env: BuildEnvironment) throws {
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()

//    try env.make("test")
    try env.make("install")
  }

}

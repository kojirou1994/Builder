import BuildSystem

struct Png: Package {
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

  var source: PackageSource {
    .tarball(url: "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz")
  }
}

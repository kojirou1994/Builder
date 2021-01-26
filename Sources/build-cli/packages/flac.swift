import BuildSystem

struct Flac: Package {
  var version: PackageVersion {
    .stable("1.3.3")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autogen()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-ogg=\(env.dependencyMap[Ogg.self].root.path)",
      env.isBuildingCross ? configureEnableFlag(false, "asm-optimizations") : nil
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.xiph.org/releases/flac/flac-1.3.3.tar.xz")
  }

  var dependencies: PackageDependency {
    .packages(Ogg.defaultPackage())
  }
}

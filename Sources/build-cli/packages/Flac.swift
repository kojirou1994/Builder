import BuildSystem

struct Flac: Package {
  var version: PackageVersion {
    .stable("1.3.3")
  }

  func build(with env: BuildEnvironment) throws {
    /*
     add -mfpu=neon to cflags and ldflags on arm
     */
    let useASM = env.target.arch == .x86_64
    try env.autogen()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-ogg=\(env.dependencyMap[Ogg.self].root.path)",
      configureEnableFlag(cpplibs, "cpplibs"),
      configureEnableFlag(false, "64-bit-words"),
      configureEnableFlag(false, "examples"),
      configureEnableFlag(useASM, "asm-optimizations", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.xiph.org/releases/flac/flac-1.3.3.tar.xz")
  }
  @Flag
  var cpplibs: Bool = false
  /*
   --enable-64-bit-words
   */

  var dependencies: PackageDependency {
    .packages(Ogg.defaultPackage)
  }
}

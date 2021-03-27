import BuildSystem

struct Flac: Package {
  var defaultVersion: PackageVersion {
    .stable("1.3.3")
  }

  var products: [BuildProduct] {
    [
      .library(name: "libFLAC", headers: ["FLAC"])
    ]
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
      ogg ? "--with-ogg=\(env.dependencyMap[Ogg.self].root.path)" : configureEnableFlag(false, "ogg"),
      configureEnableFlag(cpplibs, "cpplibs"),
      configureEnableFlag(false, "64-bit-words"),
      configureEnableFlag(false, "examples"),
      configureEnableFlag(useASM, "asm-optimizations", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    var versionString = version.toString(includeZeroPatch: false)
    if version < "1.0.3" {
      versionString += "-src"
    }
    let suffix: String
    if version < "1.3.0" {
      suffix = "gz"
    } else {
      suffix = "xz"
    }
    return .tarball(url: "https://downloads.xiph.org/releases/flac/flac-\(versionString).tar.\(suffix)")
  }

  @Flag
  var cpplibs: Bool = false

  @Flag
  var ogg: Bool = false
  /*
   --enable-64-bit-words
   */

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    if ogg {
      return .packages(.init(Ogg.self))
    } else {
      return .empty
    }
  }

  var tag: String {
    var str = ""
    if cpplibs {
      str.append("CPPLIBS")
    }
    if ogg {
      str.append("OGG")
    }
    return str
  }
}

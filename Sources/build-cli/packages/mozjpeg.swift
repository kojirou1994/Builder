import BuildSystem

struct Mozjpeg: Package {
  var version: PackageVersion {
    .stable("4.0.0")
  }

  func build(with env: BuildEnvironment) throws {

//    switch env.target.arch {
//    case .arm64, .armv7:
//      print("Use own env")
////      env.environment["CFLAGS"] =
////        "-Wall -arch arm64 -miphoneos-version-min=8.0 -funwind-tables"
////        "-arch \(env.target.arch.rawValue) -funwind-tables -Wall"
////      env.environment["LDFLAGS"] = nil
////      env.environment["CFLAGS", default: ""].append(" -funwind-tables -Wall")
//    default: break
//    }

    try env.changingDirectory("build_dir") { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        env.libraryType.staticCmakeFlag,
        env.libraryType.sharedCmakeFlag,
        cmakeOnFlag(false, "PNG_SUPPORTED"),
        //      cmakeOnFlag(false, "WITH_TURBOJPEG"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/v4.0.0.tar.gz", filename: "mozjpeg-4.0.0.tar.gz")
  }

  var dependencies: PackageDependency {
    .packages(Png.defaultPackage)
  }
}

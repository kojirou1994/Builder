import BuildSystem

struct Mozjpeg: Package {

  var defaultVersion: PackageVersion {
    .stable("4.0.3")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  var products: [BuildProduct] {
    [
      .library(
        name: "libjpeg",
        headers: [
          "jconfig.h",
          "jerror.h",
          "jmorecfg.h",
          "jpeglib.h",
        ])
    ]
  }

  func build(with env: BuildEnvironment) throws {

    switch env.target.arch {
    case .arm64:
      env.environment["CFLAGS", default: ""].append(" -funwind-tables -Wall")
    case .armv7:
      env.environment["CFLAGS", default: ""].append(" -mfloat-abi=softfp -Wall")
    default: break
    }

    try env.changingDirectory("build_dir") { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        env.libraryType.staticCmakeFlag,
        env.libraryType.sharedCmakeFlag,
        cmakeOnFlag(false, "PNG_SUPPORTED"),
        cmakeOnFlag(false, "WITH_TURBOJPEG"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }
  }

  //  var dependencies: PackageDependency {
  //    .packages(Png.defaultPackage)
  //  }
}

import BuildSystem

public struct Mozjpeg: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("4.0.3")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public var products: [BuildProduct] {
    [
      .library(
        name: "libjpeg",
        headers: [
          "jconfig.h",
          "jerror.h",
          "jmorecfg.h",
          "jpeglib.h",
        ]),
      .library(
        name: "libturbojpeg",
        headers: [
          "turbojpeg.h"
        ]),
    ]
  }

  public func build(with env: BuildEnvironment) throws {

    switch env.target.arch {
    case .arm64:
      env.environment.append("-funwind-tables -Wall", for: .cflags)
    case .armv7:
      env.environment.append("-mfloat-abi=softfp -Wall", for: .cflags)
    default: break
    }

    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        env.libraryType.staticCmakeFlag,
        env.libraryType.sharedCmakeFlag,
        cmakeOnFlag(true, "PNG_SUPPORTED"),
        cmakeOnFlag(true, "WITH_TURBOJPEG"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Png.self))
  }
}

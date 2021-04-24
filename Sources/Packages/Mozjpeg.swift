import BuildSystem

public struct Mozjpeg: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "4.0.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Png.self)
      ),
      products: [
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
    )
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

}

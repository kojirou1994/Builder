import BuildSystem

public struct Mozjpeg: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "4.1.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/mozilla/mozjpeg.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/mozilla/mozjpeg/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(Nasm.self),
        .runTime(Png.self),
      ],
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

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        context.libraryType.staticCmakeFlag,
        context.libraryType.sharedCmakeFlag,
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(true, "PNG_SUPPORTED"),
        cmakeOnFlag(true, "WITH_TURBOJPEG"),
        cmakeOnFlag(false, "WITH_12BIT"), // simd will be disabled if 12bit is enabled
//        cmakeOnFlag(true, "WITH_JPEG7"),
//        cmakeOnFlag(true, "WITH_JPEG8"),
        nil
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }

}

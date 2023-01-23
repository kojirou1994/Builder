import BuildSystem

private let minVersion: PackageVersion = "0.7.0"

public struct JpegXL: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.8.0"
  }

// TODO: use bundled highway repo
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    guard order.version > minVersion else {
      throw PackageRecipeError.unsupportedVersion
    }

    let repoUrl = "https://github.com/libjxl/libjxl.git"

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: repoUrl)
    case .stable(let version):
      source = .repository(url: repoUrl, requirement: .tag("v\(version.toString())"), submodule: .paths(["third_party/sjpeg", "third_party/skcms"]))
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Highway.self),
        .runTime(Brotli.self),
        .runTime(Mozjpeg.self),
        .runTime(Openexr.self),
        .runTime(Webp.self),
        .runTime(Giflib.self),
        .runTime(Png.self),
        .runTime(Libavif.self),
        .runTime(Gflags.self),
      ],
      products: [
        .bin("cjxl"), .bin("djxl"),
        .library(name: "CJXL", libname: "libjxl", headerRoot: "jxl", headers: ["decode.h", "parallel_runner.h"], shimedHeaders: []),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.libraryType.buildStatic, "JPEGXL_STATIC"),
        cmakeOnFlag(false, "JPEGXL_ENABLE_MANPAGES"),
        cmakeOnFlag(true, "JPEGXL_ENABLE_PLUGINS"),
        cmakeOnFlag(true, "JPEGXL_FORCE_SYSTEM_BROTLI"),
        cmakeOnFlag(true, "JPEGXL_FORCE_SYSTEM_GTEST"),
        cmakeOnFlag(true, "JPEGXL_FORCE_SYSTEM_HWY"),
        cmakeOnFlag(false, "BUILD_TESTING")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
  }
}

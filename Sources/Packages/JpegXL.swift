import BuildSystem

public struct JpegXL: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.6.1"
  }

// TODO: use bundled highway repo
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let repoUrl = "https://github.com/libjxl/libjxl.git"

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: repoUrl)
    case .stable(let version):
      source = .repository(url: repoUrl, requirement: .tag("v\(version.toString(includeZeroPatch: false))"))
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Brotli.self),
        .runTime(Mozjpeg.self),
        .runTime(Openexr.self),
        .runTime(Webp.self),
        .runTime(Giflib.self),
        .runTime(Png.self),
        .runTime(Libavif.self),
        order.version > "0.6.1" ? .runTime(Gflags.self) : nil,
      ],
      products: [
        .bin("cjxl"), .bin("djxl"),
        .library(name: "CJXL", libname: "libjxl", headerRoot: "jxl", headers: ["decode.h", "parallel_runner.h"], shimedHeaders: []),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "CMakeLists.txt", matching: "find_package(Python COMPONENTS Interpreter)", with: "") // disable manpages

    try context.inRandomDirectory { _ in

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        context.order.version > "0.6.1" ? cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS") : nil,
        context.order.version > "0.6.1" ? cmakeOnFlag(context.libraryType.buildStatic, "JPEGXL_STATIC") : nil,
        cmakeOnFlag(true, "SJPEG_BUILD_EXAMPLES"),
        cmakeOnFlag(false, "JPEGXL_ENABLE_MANPAGES"),
        cmakeOnFlag(true, "JPEGXL_ENABLE_PLUGINS"),
        cmakeOnFlag(true, "JPEGXL_FORCE_SYSTEM_BROTLI"),
        cmakeOnFlag(true, "JPEGXL_FORCE_SYSTEM_GTEST"),
        cmakeOnFlag(false, "JPEGXL_FORCE_SYSTEM_HWY"),
        cmakeOnFlag(false, "BUILD_TESTING")
      )

      // fix darwin ld
      try replace(contentIn: "build.ninja", matching: "-Wl,--exclude-libs=ALL", with: "")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
  }
}

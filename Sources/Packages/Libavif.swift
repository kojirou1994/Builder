import BuildSystem

public struct Libavif: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.9.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let repoUrl = "https://github.com/AOMediaCodec/libavif.git"

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: repoUrl)
    case .stable(let version):
      source = .repository(url: repoUrl, requirement: .tag("v\(version.toString())"))
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Rav1e.self),
        .runTime(Dav1d.self),
        .runTime(Aom.self),
        .runTime(Png.self),
        .runTime(Mozjpeg.self),
        // .runTime(SvtAv1.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "AVIF_CODEC_AOM"),
        cmakeOnFlag(true, "AVIF_CODEC_DAV1D"),
        cmakeOnFlag(true, "AVIF_CODEC_RAV1E"),
        // cmakeOnFlag(true, "AVIF_CODEC_SVT")

        cmakeOnFlag(true, "AVIF_BUILD_APPS"),
        cmakeOnFlag(false, "AVIF_BUILD_EXAMPLES"),
        cmakeOnFlag(false, "AVIF_BUILD_TESTS"),
        cmakeOnFlag(true, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(false, "AVIF_ENABLE_WERROR"), /* jpeg header error */
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}
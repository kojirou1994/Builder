import BuildSystem

public struct MediaInfoLib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "22.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)
      source = .tarball(url: "https://github.com/MediaArea/MediaInfoLib/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Zlib.self),
        .runTime(ZenLib.self),
        .runTime(Curl.self),
        .runTime(Tinyxml2.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    context.environment.append("-lcurl", for: .ldflags)
    
    try context.changingDirectory("Project/CMake") { _ in
      try context.inRandomDirectory { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(false, "BUILD_ZLIB"),
          cmakeOnFlag(false, "BUILD_ZENLIB")
        )

        try context.make(toolType: .ninja)
        // no test
        try context.make(toolType: .ninja, "install")
      }
    }
  }
}

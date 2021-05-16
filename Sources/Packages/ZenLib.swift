import BuildSystem

public struct ZenLib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.4.39"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/MediaArea/ZenLib/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory("Project/CMake") { _ in
      try context.inRandomDirectory { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
          cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(true, "CMAKE_MACOSX_RPATH")
        )

        try context.make(toolType: .ninja)
        // no test
        try context.make(toolType: .ninja, "install")
      }
    }
  }
}

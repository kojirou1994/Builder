import BuildSystem

public struct Ilmbase: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.5.8"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      if version < "3.0.0" {
        source = .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
      } else {
        throw PackageRecipeError.unsupportedVersion
      }
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory("IlmBase/" + context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeDefineFlag("", "ILMBASE_STATIC_LIB_SUFFIX")
      )
      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }

}

import BuildSystem

public struct Pugixml: Package {

  public init() {}
  
  public var defaultVersion: PackageVersion {
    "1.12.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/zeux/pugixml/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/zeux/pugixml/archive/refs/tags/v\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        context.libraryType.buildShared ? cmakeOnFlag(true, context.libraryType.buildStatic ? "BUILD_SHARED_AND_STATIC_LIBS" : "BUILD_SHARED_LIBS") : nil
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}

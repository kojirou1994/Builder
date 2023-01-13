import BuildSystem

public struct Ebml: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ],
      products: [
        .library(name: "libebml", headers: ["ebml"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    // can't build both static and shared library, the headers are different
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }

}

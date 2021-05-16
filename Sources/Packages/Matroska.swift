import BuildSystem

public struct Matroska: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.6.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let ext: String
      if version >= "1.4.8" {
        ext = "xz"
      } else if version >= "0.7.0" {
        ext = "bz2"
      } else {
        // older version not important
        ext = "gz"
      }
      source = .tarball(url: "https://dl.matroska.org/downloads/libmatroska/libmatroska-\(version.toString()).tar.\(ext)")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Ebml.self),
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      products: [
        .library(name: "matroska", headers: ["matroska"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
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

import BuildSystem

public struct Png: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.6.37"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/glennrp/libpng.git")
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/libpng/libpng16/\(version)/libpng-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Zlib.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(context.order.arch.isARM ? "on" : "off" , "PNG_ARM_NEON"),
        cmakeOnFlag(context.libraryType.buildStatic, "PNG_STATIC"),
        cmakeOnFlag(context.libraryType.buildShared, "PNG_SHARED"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
      )

      try context.make(toolType: .ninja)

      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }

      try context.make(toolType: .ninja, "install")

    }
  }

}

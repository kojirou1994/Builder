import BuildSystem

public struct Fmt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "8.0.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/fmtlib/fmt/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    func build(shared: Bool) throws {
      try context.changingDirectory(context.randomFilename) { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(false, "FMT_TEST"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS")
        )

        try context.make(toolType: .ninja)
        try context.make(toolType: .ninja, "install")
      }
    }

    try build(shared: context.libraryType.buildShared)
    if context.libraryType == .all {
      try build(shared:false)
    }
  }

}

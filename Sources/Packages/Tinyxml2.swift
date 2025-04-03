import BuildSystem

public struct Tinyxml2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "11.0.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/leethomason/tinyxml2.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/leethomason/tinyxml2/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .make,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "tinyxml2_SHARED_LIBS"),
        cmakeOnFlag(context.strictMode, "tinyxml2_BUILD_TESTING")
      )

      try context.make()

      if context.canRunTests {
        try context.make("test")
      }

      try context.make("install")
    }
  }
}

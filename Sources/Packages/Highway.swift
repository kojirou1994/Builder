import BuildSystem

public struct Highway: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/google/highway.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/google/highway/archive/refs/tags/\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        // TODO: should use buildTime runTime
        .runTime(Googletest.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    /*
     BUILD_TESTING means build google test
     */
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        context.strictMode ? cmakeOnFlag(true, "HWY_SYSTEM_GTEST") : nil,
        cmakeOnFlag(false, "HWY_ENABLE_EXAMPLES"),
        cmakeOnFlag(context.strictMode, "BUILD_TESTING")
      )

      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }
}

import BuildSystem

public struct Googletest: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.11.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/google/googletest.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/google/googletest/archive/refs/tags/release-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      supportedLibraryType: .static
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.strictMode, "gmock_build_tests"),
        cmakeOnFlag(context.strictMode, "gtest_build_samples"),
        cmakeOnFlag(context.strictMode, "gtest_build_tests")
      )

      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }
}

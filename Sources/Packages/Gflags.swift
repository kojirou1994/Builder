import BuildSystem

public struct Gflags: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.2.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let repoUrl = "https://github.com/gflags/gflags.git"

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: repoUrl)
    case .stable(let version):
      source = .repository(url: repoUrl, requirement: .tag("v\(version.toString(includeZeroPatch: version > "2.0"))"))
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
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.libraryType.buildStatic, "BUILD_STATIC_LIBS"),
        cmakeOnFlag(false, "BUILD_TESTING")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}
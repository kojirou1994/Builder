import BuildSystem

public struct NlohmannJson: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.9.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/nlohmann/json/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: [
          .buildTool(Cmake.self),
          .buildTool(Ninja.self),
       ]),
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.strictMode, "JSON_BuildTests"),
        cmakeOnFlag(true, "JSON_MultipleHeaders")
      )

      try env.make(toolType: .ninja)
      if env.strictMode {
        try env.make(toolType: .ninja, "test")
      }
      try env.make(toolType: .ninja, "install")
    }
  }

}

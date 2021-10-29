import BuildSystem

public struct NlohmannJson: Package {
  
  public init() {}
  
  public var defaultVersion: PackageVersion {
    "3.10.4"
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
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      supportedLibraryType: nil
    )
  }
  
  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.strictMode, "JSON_BuildTests"),
        cmakeOnFlag(true, "JSON_MultipleHeaders")
      )
      
      try context.make(toolType: .ninja)
      if context.strictMode {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }
  
}

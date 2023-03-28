import BuildSystem

public struct Fish: Package {
  
  public init() {}
  
  public var defaultVersion: PackageVersion {
    "3.6.1"
  }
  
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/fish-shell/fish-shell/releases/download/\(version.toString())/fish-\(version.toString()).tar.xz")
    }
    
    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Pcre2.self),
        .runTime(Gettext.self),
      ],
      supportedLibraryType: nil
    )
  }
  
  public func build(with context: BuildContext) throws {
    context.environment.append("-lintl -liconv", for: .ldflags)
    if context.order.system.isApple {
      context.environment.append("-Wl,-framework -Wl,CoreFoundation", for: .ldflags)
    }
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        nil
      )
      
      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
  
}

import BuildSystem

public struct Fish: Package {
  
  public init() {}
  
  public var defaultVersion: PackageVersion {
    "3.2.2"
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
  
  public func build(with env: BuildEnvironment) throws {
    env.environment.append("-lintl -liconv", for: .ldflags)
    if env.order.target.system.isApple {
      env.environment.append("-Wl,-framework -Wl,CoreFoundation", for: .ldflags)
    }
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        nil
      )
      
      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }
  }
  
}

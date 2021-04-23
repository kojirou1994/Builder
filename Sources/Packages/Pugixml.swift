import BuildSystem

public struct Pugixml: Package {

  public init() {}
  
  public var defaultVersion: PackageVersion {
    "1.11.4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/zeux/pugixml/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/zeux/pugixml/archive/refs/tags/v\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .packages(
        .init(Cmake.self, options: .init(buildTimeOnly: true)),
        .init(Ninja.self, options: .init(buildTimeOnly: true))
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        env.libraryType.buildShared ? cmakeOnFlag(true, env.libraryType.buildStatic ? "BUILD_SHARED_AND_STATIC_LIBS" : "BUILD_SHARED_LIBS") : nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    })
  }
}

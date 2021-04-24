import BuildSystem

public struct Ninja: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.10.2")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(packages: .buildTool(Cmake.self)),
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .make, 
        ".."
        /* -DBUILD_TESTING */
      )

      try env.make()

      try env.make("install")
    }
  }

}

import BuildSystem

public struct Ninja: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.10.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/ninja-build/ninja.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [.buildTool(Cmake.self)],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .make, 
        ".."
        /* -DBUILD_TESTING */
      )

      try context.make()

      try context.make("install")
    }
  }

}

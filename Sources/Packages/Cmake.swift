import BuildSystem

/*
 requires libssl-dev on linux
 */
public struct Cmake: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.30.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/Kitware/CMake/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/Kitware/CMake/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(source: source, supportedLibraryType: nil)
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.launch(
        path: "../bootstrap",
        "--prefix=\(context.prefix.root.path)",
        "--no-system-libs",
        "--parallel=\(context.parallelJobs ?? 1)"
      )

      try context.make()

      try context.make("install")
    }
  }

}

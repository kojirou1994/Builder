import BuildSystem

public struct Node: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "18.9.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/nodejs/node/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/nodejs/node/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Ninja.self),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {

    try context.launch(
      path: "configure",
      "--prefix=\(context.prefix.root.path)",
      "--ninja",
      configureWithFlag("softfp", "arm-float-abi"),
      configureWithFlag("neon", "arm-fpu")
    )

    context.environment.append("-j4", for: "NINJA_ARGS")

    try context.make(parallelJobs: 4, "install")
  }

}

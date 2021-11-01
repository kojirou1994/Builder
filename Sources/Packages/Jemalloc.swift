import BuildSystem

public struct Jemalloc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/jemalloc/jemalloc/archive/refs/heads/dev.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/jemalloc/jemalloc/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [.library(name: "jemalloc", headers: ["jemalloc"])]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")

  }

}

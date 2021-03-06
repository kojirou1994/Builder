import BuildSystem

public struct Yasm: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    let dep: [PackageDependency]
    switch order.version {
    case .head:
      dep = [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ]
      source = .tarball(url: "https://github.com/yasm/yasm/archive/refs/heads/master.zip")
    case .stable(let version):
      dep = []
      source = .tarball(url: "https://www.tortall.net/projects/yasm/releases/yasm-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: dep,
      supportedLibraryType: .static)
  }

  public func build(with context: BuildContext) throws {
    if context.order.version == .head {
      try context.autogen()
    }
    try context.configure()
    try context.make()
    try context.make("install")
  }
}

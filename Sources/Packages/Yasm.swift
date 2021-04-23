import BuildSystem

public struct Yasm: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    let dep: PackageDependencies
    switch order.version {
    case .head:
      dep = .blend(packages: [], brewFormulas: ["autoconf", "automake"])
      source = .tarball(url: "https://github.com/yasm/yasm/archive/refs/heads/master.zip")
    case .stable(let version):
      dep = .empty
      source = .tarball(url: "https://www.tortall.net/projects/yasm/releases/yasm-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: dep,
      supportedLibraryType: .static)
  }

  public func build(with env: BuildEnvironment) throws {
    if env.version == .head {
      try env.autogen()
    }
    try env.configure()
    try env.make()
    try env.make("install")
  }
}

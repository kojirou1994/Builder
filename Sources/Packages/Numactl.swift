import BuildSystem

public struct Numactl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0.14"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    guard case .linuxGNU = order.target.system else {
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/numactl/numactl/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/numactl/numactl/releases/download/v\(version.toString())/numactl-\(version.toString()).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {
    try context.configure()
    try context.make("install")
  }

}

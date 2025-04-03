import BuildSystem

public struct Meson: PipPackage {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    .init(
      source: .empty,
      dependencies: [
        .runTime(Python.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch("pip3", "install", "meson")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }
  
}

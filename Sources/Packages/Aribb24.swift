import BuildSystem

public struct Aribb24: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.0.3")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/nkoriyama/aribb24/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .packages(.init(Png.self)))
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "bootstrap")
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}

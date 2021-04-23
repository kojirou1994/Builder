import BuildSystem

public struct FdkAac: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(otherPackages: [.brewAutoConf])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(example, "example")
    )
    try env.make("install")
  }
  
  @Flag(inversion: .prefixedEnableDisable, help: "Enable example encoding program.")
  var example: Bool = false

}

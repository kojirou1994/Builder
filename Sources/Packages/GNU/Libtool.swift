import BuildSystem

public struct Libtool: Package {

  public init() {}

  @Flag
  var ltdl: Bool = false

  public var defaultVersion: PackageVersion {
    "2.4.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/libtool/libtool-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(packages: .buildTool(M4.self)),
      supportedLibraryType: ltdl ? .all : nil
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(ltdl, "ltdl-install"),
//      "--program-prefix=g"
      nil
    )

    try env.make()
    try env.make("install")
  }

}

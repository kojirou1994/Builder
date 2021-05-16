import BuildSystem

public struct Lame: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.100"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://nchc.dl.sourceforge.net/project/lame/lame/\(versionString)/lame-\(versionString).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "include/libmp3lame.sym", matching: "lame_init_old\n", with: "")

//    try context.autoreconf()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(context.isBuildingNative, "nasm"),
      configureEnableFlag(false, "frontend")
    )

    try context.make("install")
  }

}

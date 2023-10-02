import BuildSystem

public struct Sdl2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.26.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.system {
    case .watchOS, .watchSimulator,
         .macCatalyst:
      throw PackageRecipeError.unsupportedTarget
    default: break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/libsdl-org/SDL.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/libsdl-org/SDL/archive/refs/tags/release-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(Zlib.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()

    try context.configure(
      context.libraryType.sharedConfigureFlag,
      context.libraryType.staticConfigureFlag,
      configureEnableFlag(true, "arm-simd"),
      configureEnableFlag(true, "arm-neon"),
      configureWithFlag(false, "x")
    )

    try context.make()
    try context.make("install")
  }

}

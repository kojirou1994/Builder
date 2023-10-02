import BuildSystem

public struct Fribidi: Package {

  public init() {}

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.meson(
        "..",
        "--default-library=\(context.libraryType.mesonFlag)"
      )

      try context.launch("ninja")
      try context.launch("ninja", "install")
    }
  }

  public var defaultVersion: PackageVersion {
    "1.0.13"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/fribidi/fribidi/releases/download/v\(version.toString())/fribidi-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
      ]
    )
  }

}

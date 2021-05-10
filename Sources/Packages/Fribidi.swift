import BuildSystem

public struct Fribidi: Package {

  public init() {}

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.meson(
        "..",
        "--default-library=\(env.libraryType.mesonFlag)"
      )

      try env.launch("ninja")
      try env.launch("ninja", "install")
    }
  }

  public var defaultVersion: PackageVersion {
    "1.0.10"
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
      dependencies: [.buildTool(Ninja.self)]
    )
  }

}

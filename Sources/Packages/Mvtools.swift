import BuildSystem

public struct Mvtools: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.meson("..")

      try context.launch("ninja")
      try context.launch("ninja", "install")
    }
  }
}

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
      dependencies: PackageDependencies(
        packages: .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.meson("..")

      try env.launch("ninja")
      try env.launch("ninja", "install")
    }
  }
}

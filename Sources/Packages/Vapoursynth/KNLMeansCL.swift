import BuildSystem

public struct KNLMeansCL: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    if env.order.version > "1.1.1" {
      try env.changingDirectory(env.randomFilename) { _ in
        try env.meson("..")

        try env.launch("ninja")
        try env.launch("ninja", "install")
      }
    } else {
      try env.launch(path: "./configure", "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)")

      try env.make()
      try env.make("install")
    }

  }
}

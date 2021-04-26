import BuildSystem

public struct NeoGradientMask: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_Gradient_Mask/archive/refs/heads/master.zip")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
//      let filename = "libneo-fft3d.\(env.target.system.sharedLibraryExtension)"
//
//      let installDir = env.prefix.lib.appendingPathComponent("vapoursynth")
//      try env.fm.createDirectory(at: installDir)
//
//      try env.fm.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
    })
  }
}

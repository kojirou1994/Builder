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
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(toolType: .ninja, "..")

      try context.make(toolType: .ninja)
//      let filename = "libneo-fft3d.\(context.target.system.sharedLibraryExtension)"
//
//      let installDir = context.prefix.lib.appendingPathComponent("vapoursynth")
//      try context.mkdir(installDir)
//
//      try context.mkdir(URL(fileURLWithPath: filename), toDirectory: installDir)
    }
  }
}

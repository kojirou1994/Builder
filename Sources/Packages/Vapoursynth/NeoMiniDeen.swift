import BuildSystem

public struct NeoMiniDeen: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
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
    }
  }
}

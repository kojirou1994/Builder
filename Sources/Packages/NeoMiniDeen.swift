import BuildSystem

public struct NeoMiniDeen: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("10")
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
      dependencies: .packages(
      .init(Cmake.self, options: .init(buildTimeOnly: true)),
      .init(Ninja.self, options: .init(buildTimeOnly: true))
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
    })
  }
}

import BuildSystem

public struct Libevent: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.1.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/libevent/libevent/archive/refs/tags/release-\(version.toString(includeZeroPatch: false))-stable.tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Openssl.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.inRandomDirectory { _ in

      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(env.libraryType == .all ? "BOTH" : env.libraryType.rawValue, "EVENT__LIBRARY_TYPE")
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }

  }
}

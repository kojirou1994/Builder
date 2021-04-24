import BuildSystem

public struct Ebml: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ),
      products: [.library(name: "libebml", headers: ["ebml"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    // build alone
    if env.libraryType.buildStatic {
      try env.changingDirectory(env.randomFilename, block: { _ in
        try env.cmake(
          toolType: .ninja,
          ".."
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      })
    }

    if env.libraryType.buildShared {
      try env.changingDirectory(env.randomFilename, block: { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(true, "BUILD_SHARED_LIBS")
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      })
    }

  }

}

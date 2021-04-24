import BuildSystem

public struct Matroska: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.6.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let ext: String
      if version >= "1.4.8" {
        ext = "xz"
      } else if version >= "0.7.0" {
        ext = "bz2"
      } else {
        // older version not important
        ext = "gz"
      }
      source = .tarball(url: "https://dl.matroska.org/downloads/libmatroska/libmatroska-\(version.toString()).tar.\(ext)")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(packages: .runTime(Ebml.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {
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

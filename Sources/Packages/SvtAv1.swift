import BuildSystem

public struct SvtAv1: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.8.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/master/SVT-AV1-master.tar.gz")
    case .stable(let version):
      source = .tarball(url: "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v0.8.6/SVT-AV1-v\(version.toString()).tar.gz")
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
    // TODO: add BUILD_TESTING
    if env.libraryType.buildStatic {
      try env.changingDirectory(env.randomFilename, block: { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(false, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(!env.libraryType.buildShared, "BUILD_APPS") // preserve building twice
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

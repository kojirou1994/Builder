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
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ],
      products: [.library(name: "libebml", headers: ["ebml"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS")
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      }
    }

    try build(shared: env.libraryType.buildShared)
    if env.libraryType == .all {
      try build(shared: false)
    }
  }

}

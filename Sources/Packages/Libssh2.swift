import BuildSystem

public struct Libssh2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://libssh2.org/download/libssh2-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Zlib.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(false, "BUILD_EXAMPLES"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
//        cmakeOnFlag(true, "CLEAR_MEMORY"),
        cmakeOnFlag(true, "ENABLE_CRYPT_NONE"),
        cmakeOnFlag(true, "ENABLE_ZLIB_COMPRESSION")
      )

      try context.make(toolType: .ninja)

      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }

      try context.make(toolType: .ninja, "install")
    }
  }
}

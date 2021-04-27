import BuildSystem

public struct Freetype: Package {

  public var defaultVersion: PackageVersion {
    "2.10.4"
  }

  @Flag
  var withHarfbuzz: Bool = false

  public var tag: String {
    (withHarfbuzz ? "harfbuzz" : "")
  }

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://downloads.sourceforge.net/project/freetype/freetype2/\(versionString)/freetype-\(versionString).tar.xz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: [
          .buildTool(Cmake.self),
          .buildTool(Ninja.self),
          .buildTool(PkgConfig.self),
          .runTime(Png.self),
          .runTime(Bzip2.self),
          .runTime(Brotli.self),
          withHarfbuzz ? .runTime(Harfbuzz.self) : nil
        ])
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(true, "FT_WITH_BROTLI"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
          cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
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

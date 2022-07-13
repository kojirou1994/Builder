import BuildSystem

public struct Freetype: Package {
  
  public var defaultVersion: PackageVersion {
    "2.12.1"
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
      source = .tarball(url: "https://download.savannah.gnu.org/releases/freetype/freetype-\(versionString).tar.xz")
    }
    
    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Png.self),
        .runTime(Bzip2.self),
        .runTime(Brotli.self),
        withHarfbuzz ? .runTime(Harfbuzz.self) : nil
      ],
      canBuildAllLibraryTogether: false
    )
  }
  
  public func build(with context: BuildContext) throws {

    try replace(contentIn: "CMakeLists.txt", matching: "find_package(HarfBuzz ${HARFBUZZ_MIN_VERSION})", with: "")

    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "FT_WITH_BROTLI"),
        cmakeOnFlag(false, "FT_WITH_HARFBUZZ"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}

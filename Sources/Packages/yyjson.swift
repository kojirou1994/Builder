import BuildSystem

public struct yyjson: Package {

  public init() {}

  @Flag(inversion: .prefixedEnableDisable)
  var misc: Bool = true

  public var tag: String {
    [
      misc ? "" : "NO_MISC",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

  public var defaultVersion: PackageVersion {
    "0.6.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/ibireme/yyjson/archive/refs/tags/\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        misc ? .runTime(Gmp.self) : nil,
        misc ? .runTime(Mpfr.self) : nil,
      ],
      products: [
        misc ? .bin("jsoninfo") : nil,
        .library(name: "yyjson", libname: "yyjson", headerRoot: "", headers: [], shimedHeaders: []),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  /*
   YYJSON_DISABLE_COMMENT_READER    OFF
   YYJSON_DISABLE_FP_READER         OFF
   YYJSON_DISABLE_FP_WRITER         OFF
   YYJSON_DISABLE_INF_AND_NAN_REA   OFF
   YYJSON_DISABLE_READER            OFF
   YYJSON_DISABLE_WRITER            OFF
   YYJSON_ENABLE_COVERAGE           OFF
   YYJSON_ENABLE_SANITIZE           OFF
   YYJSON_ENABLE_VALGRIND           OFF
   */
  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(misc, "YYJSON_BUILD_MISC"),
        cmakeOnFlag(context.canRunTests, "YYJSON_BUILD_TESTS")
      )

      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")

      if misc {
        try context.install(URL(fileURLWithPath: "jsoninfo"), URL(fileURLWithPath: "make_tables"), toDirectory: context.prefix.bin)
      }
    }
  }
}

extension BuildContext {
  public func install(_ files: URL..., toDirectory directory: URL) throws {
    try mkdir(directory)
    try files.forEach({ file in
      let dst =  directory.appendingPathComponent(file.lastPathComponent)
      try? removeItem(at: dst)
      try copyItem(at: file, to: dst)
    })
  }
}

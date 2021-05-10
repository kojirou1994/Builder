import BuildSystem

public struct Zstd: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.9"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/facebook/zstd/archive/refs/heads/dev.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/facebook/zstd/archive/refs/tags/v\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        programs ? .runTime(Xz.self) : nil,
        programs ? .runTime(Lz4.self) : nil,
      ],
      products: [
        .library(name: "zstd", headers: ["zdict.h", "zstd_errors.h", "zstd.h"])
      ]
    )
  }

  @Flag(inversion: .prefixedEnableDisable, help: "Disable programs to build on tvOS or other systems")
  var programs: Bool = true

  @Flag(inversion: .prefixedEnableDisable)
  var legacy: Bool = true

  public var tag: String {
    [
      programs ? "" : "NO-PROGRAMS",
      legacy ? "" : "NO-LEGACY",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build/cmake") { _ in

      try env.inRandomDirectory { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(env.libraryType.buildStatic, "ZSTD_BUILD_STATIC"),
          cmakeOnFlag(env.libraryType.buildShared, "ZSTD_BUILD_SHARED"),
          cmakeOnFlag(env.strictMode, "ZSTD_BUILD_TESTS"),
          cmakeOnFlag(legacy, "ZSTD_LEGACY_SUPPORT"),
          cmakeOnFlag(programs, "ZSTD_BUILD_PROGRAMS"),
          cmakeOnFlag(env.libraryType == .shared || (env.libraryType == .all && !env.prefersStaticBin), "ZSTD_PROGRAMS_LINK_SHARED"),
          cmakeOnFlag(programs, "ZSTD_LZ4_SUPPORT", defaultEnabled: false),
          cmakeOnFlag(programs, "ZSTD_LZMA_SUPPORT", defaultEnabled: false),
          cmakeOnFlag(programs, "ZSTD_ZLIB_SUPPORT", defaultEnabled: false),
          cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeDefineFlag("@loader_path/../lib", "CMAKE_BUILD_RPATH") // fix for test time dyld error
        )

        try env.make(toolType: .ninja)

        if env.canRunTests {
          try env.make(toolType: .ninja, "test")
        }

        try env.make(toolType: .ninja, "install")
      }

    }
  }
}

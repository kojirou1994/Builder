import BuildSystem

public struct Libarchive: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.5.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.system {
    case .watchOS, .watchSimulator,
         .tvOS, .tvSimulator:
      /*
       libarchive/filter_fork_posix.c:187:2: error: 'posix_spawn_file_actions_destroy' is unavailable: not available on watchOS
       */
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/libarchive/libarchive/releases/download/\(versionString)/libarchive-\(versionString).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Lz4.self),
        .runTime(Zstd.self),
        .runTime(Xz.self),
        .runTime(Libb2.self),
        .runTime(Lzo.self),
        .runTime(Mbedtls.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    /*
     still failed:
    switch context.order.system {
    case .watchOS, .watchSimulator,
         .tvOS, .tvSimulator:
      try [
        "posix_spawnp HAVE_POSIX_SPAWNP",
        "fork HAVE_FORK",
        "vfork HAVE_VFORK",
      ].forEach { fn in
        try replace(contentIn: "CMakeLists.txt", matching: "CHECK_FUNCTION_EXISTS_GLIBC(\(fn))", with: "")
      }
    default:
      break
    }
    */

    try context.inRandomDirectory { _ in

      let enableShared = context.libraryType == .shared || ( context.libraryType == .all && !context.prefersStaticBin )
      let enableTests = context.canRunTests && context.order.system != .macCatalyst /* tests require system() function */

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(enableTests, "BUILD_TESTING"),
        cmakeOnFlag(enableTests, "ENABLE_TEST"),
        cmakeOnFlag(enableShared, "ENABLE_TAR_SHARED"),
        cmakeOnFlag(enableShared, "ENABLE_CAT_SHARED"),
        cmakeOnFlag(enableShared, "ENABLE_CPIO_SHARED"),
        cmakeOnFlag(true, "ENABLE_LZO"),
        cmakeOnFlag(true, "ENABLE_MBEDTLS"),
        // ENABLE_NETTLE
        nil
      )

      try context.make(toolType: .ninja)
      if enableTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")

      try context.autoRemoveUnneedLibraryFiles()
    }
  }
}

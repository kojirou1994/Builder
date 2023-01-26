import BuildSystem

public struct Libarchive: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.6.2"
  }

  @Option
  private var crypt: Crypt = .openssl

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
      source = .repository(url: "https://github.com/libarchive/libarchive.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/libarchive/libarchive/releases/download/v\(versionString)/libarchive-\(versionString).tar.xz")
    }

    let cryptDep: PackageDependency
    switch crypt {
    case .openssl: cryptDep = .runTime(Openssl.self)
    case .mbedtls: cryptDep = .runTime(Mbedtls.self)
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
        .optional(.runTime(Zlib.self), when: !order.system.isMobile),
        .optional(.runTime(Bzip2.self), when: !order.system.isMobile),
        .optional(.runTime(Xml2.self), when: !order.system.isMobile),
        cryptDep,
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    if context.order.system.isApple {
      if crypt == .openssl {
        try replace(contentIn: "CMakeLists.txt", matching: """
IF(ENABLE_OPENSSL AND NOT CMAKE_SYSTEM_NAME MATCHES "Darwin")
""", with: """
IF(ENABLE_OPENSSL)
""")
      }

      // perfer system's libs(eg. iconv) which xml2 depends on
      try replace(contentIn: "CMakeLists.txt", matching: "list(APPEND CMAKE_PREFIX_PATH /opt/local)", with: "")
    }

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
        cmakeOnFlag(crypt == .openssl, "ENABLE_OPENSSL"),
        cmakeOnFlag(crypt == .mbedtls, "ENABLE_MBEDTLS"),
        cmakeOnFlag(true, "ENABLE_LIBB2"),
        cmakeOnFlag(true, "ENABLE_LZ4"),
        cmakeOnFlag(false, "ENABLE_LZO"),
        cmakeOnFlag(true, "ENABLE_LZMA"),
        cmakeOnFlag(true, "ENABLE_ZSTD"),
        cmakeOnFlag(true, "ENABLE_ZLIB"),
        cmakeOnFlag(true, "ENABLE_BZip2"),
        cmakeOnFlag(true, "ENABLE_LIBXML2"),
        cmakeOnFlag(false, "ENABLE_EXPAT"),
        cmakeOnFlag(false, "ENABLE_LIBGCC"),
        nil
      )

      try context.make(toolType: .ninja)
      if enableTests {
        // test_sparse_basic always fails (APFS)
        context.environment["SKIP_TEST_SPARSE"] = "1"
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")

      try context.autoRemoveUnneedLibraryFiles()
    }
  }

  enum Crypt: String, PackageFeature {
    case openssl
    case mbedtls
  }
}

import BuildSystem

public struct Curl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "8.7.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/curl/curl.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://curl.se/download/curl-\(versionString).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Brotli.self),
        .runTime(Zstd.self),
        .runTime(CAres.self),
        .runTime(Openssl.self),
        .runTime(Mbedtls.self),
        .runTime(Zlib.self),
        .runTime(Nghttp2.self),
        .runTime(Libssh2.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {

    if context.cCompiler == .gcc {
      try replace(contentIn: "CMakeLists.txt", matching: "list(APPEND CURL_LIBS ${LIBSSH2_LIBRARY})", with: "list(PREPEND CURL_LIBS ${LIBSSH2_LIBRARY})")
      try replace(contentIn: "CMake/FindBrotli.cmake", matching: "set(BROTLI_LIBRARIES ${BROTLICOMMON_LIBRARY} ${BROTLIDEC_LIBRARY})", with: "set(BROTLI_LIBRARIES ${BROTLIDEC_LIBRARY} ${BROTLICOMMON_LIBRARY})")
    }

    // sec transp errors on 7.87 https://github.com/curl/curl/issues/10227
    let CURL_USE_SECTRANSP = context.order.system.isApple && context.order.version != "7.87"

    try context.inRandomDirectory { _ in
      if context.libraryType == .static {
        context.environment.append("-lresolv", for: .ldflags)
      }
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "BUILD_CURL_EXE"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),

        cmakeOnFlag(true, "CURL_USE_LIBSSH2"),
        cmakeOnFlag(false, "CURL_USE_LIBPSL"),
        cmakeOnFlag(!context.order.system.isApple, "CURL_DISABLE_LDAP"),
        cmakeOnFlag(!context.order.system.isApple, "CURL_DISABLE_LDAPS"),
        cmakeOnFlag(true, "CURL_BROTLI"),
        cmakeOnFlag(true, "CURL_USE_OPENSSL"),
        cmakeOnFlag(true, "CURL_CA_FALLBACK"),
        cmakeOnFlag(true, "ENABLE_ARES"),
        cmakeOnFlag(CURL_USE_SECTRANSP, "CURL_USE_SECTRANSP"),
        cmakeOnFlag(true, "CURL_USE_MBEDTLS"),
        cmakeOnFlag(true, "USE_NGHTTP2"),
        cmakeOnFlag(true, "CURL_ZSTD")
      )

      try context.make(toolType: .ninja)

      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }

      try context.make(toolType: .ninja, "install")
    }
  }
}

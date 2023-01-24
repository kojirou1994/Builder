import BuildSystem

public struct Curl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "7.87.0"
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
//        .runTime(Openssl.self),
        .runTime(Zlib.self),
//        .runTime(Nghttp2.self),
//        .runTime(Libssh2.self),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
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

        cmakeOnFlag(false, "CURL_USE_LIBSSH2"),
        cmakeOnFlag(false, "CURL_USE_LIBPSL"),
        cmakeOnFlag(true, "CURL_DISABLE_LDAP"),
        cmakeOnFlag(true, "CURL_BROTLI"),
        cmakeOnFlag(false, "CURL_USE_OPENSSL"),
        cmakeOnFlag(true, "CURL_CA_FALLBACK"),
        cmakeOnFlag(true, "ENABLE_ARES"),
        cmakeOnFlag(true, "CURL_USE_SECTRANSP"),
        cmakeOnFlag(false, "USE_NGHTTP2"),
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

public enum CurlOpensslBackend: String, CaseIterable, CustomStringConvertible {

  case amissl
  case bearssl
  case gnutls
  case mbedtls
  case mesalink
  case nss
  case openssl
  case boringssl
  case libressl
  case rustls
  case wintls
  case darwintls
  case wolfssl

  public var description: String { rawValue }
}
/*
 Select from these:
 --with-amissl
 --with-bearssl
 --with-gnutls
 --with-mbedtls
 --with-mesalink
 --with-nss
 --with-openssl (also works for BoringSSL and libressl)
 --with-rustls
 --with-schannel
 --with-secure-transport
 --with-wolfssl
 */

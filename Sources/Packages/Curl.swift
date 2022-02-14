import BuildSystem

public struct Curl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "7.81"
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
        .runTime(Zlib.self),
        .runTime(Libssh2.self),
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
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
        /*
         // Enable BearSSL for SSL/TLS
         CMAKE_USE_BEARSSL:BOOL=OFF

         // Use GSSAPI implementation (right now only Heimdal is supported with CMake build)
         CMAKE_USE_GSSAPI:BOOL=OFF

         // Use libSSH
         CMAKE_USE_LIBSSH:BOOL=OFF

         // Use libSSH2
         CMAKE_USE_LIBSSH2:BOOL=ON

         // Enable mbedTLS for SSL/TLS
         CMAKE_USE_MBEDTLS:BOOL=OFF

         // Enable NSS for SSL/TLS
         CMAKE_USE_NSS:BOOL=OFF

         // Use OpenLDAP code.
         CMAKE_USE_OPENLDAP:BOOL=OFF

         // Use OpenSSL code. Experimental
         CMAKE_USE_OPENSSL:BOOL=ON

         // enable Apple OS native SSL/TLS
         CMAKE_USE_SECTRANSP:BOOL=OFF

         // enable wolfSSL for SSL/TLS
         CMAKE_USE_WOLFSSL:BOOL=OFF
         // If this value is on, makefiles will be generated without the .SILENT directive, and all commands will be echoed to the console during the make.  This is useful for debugging only. With Visual Studio IDE projects all commands are done without /nologo.
         CMAKE_VERBOSE_MAKEFILE:BOOL=FALSE

         // Path to the CA bundle has been set
         CURL_CA_BUNDLE_SET:BOOL=TRUE

         // Set ON to use built-in CA store of TLS backend. Defaults to OFF
         CURL_CA_FALLBACK:BOOL=OFF

         // Path to the CA bundle has been set
         CURL_CA_PATH_SET:BOOL=TRUE

         // to disable LDAPS
         CURL_DISABLE_LDAPS:BOOL=OFF

         // to disable MQTT
         CURL_DISABLE_MQTT:BOOL=OFF

         // Disable automatic loading of OpenSSL configuration
         CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG:BOOL=OFF

         // disables TFTP
         CURL_DISABLE_TFTP:BOOL=OFF

         // to disable verbose strings
         CURL_DISABLE_VERBOSE_STRINGS:BOOL=OFF

         // Set to ON to hide libcurl internal symbols (=hide all symbols that aren't officially external).
         CURL_HIDDEN_SYMBOLS:BOOL=ON

         // Turn on compiler Link Time Optimizations
         CURL_LTO:BOOL=OFF

         // Turn compiler warnings into errors
         CURL_WERROR:BOOL=OFF

         // Build curl with ZLIB support (AUTO, ON or OFF)
         CURL_ZLIB:STRING=AUTO

         // Use libidn2 for IDN support
         USE_LIBIDN2:BOOL=ON

         // Use Nghttp2 library
         USE_NGHTTP2:BOOL=OFF

         // Use ngtcp2 and nghttp3 libraries for HTTP/3 support
         USE_NGTCP2:BOOL=OFF

         // Use quiche library for HTTP/3 support
         USE_QUICHE:BOOL=OFF
         */
        cmakeOnFlag(true, "CURL_DISABLE_LDAP"),
        cmakeOnFlag(true, "CURL_BROTLI"),
        cmakeOnFlag(true, "ENABLE_ARES"),
//        cmakeOnFlag(true, "CMAKE_USE_SECTRANSP"),
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

import BuildSystem

public struct Libssh2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.11.1"
  }

  @Option
  private var crypto: CryptoBackend = .openssl

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/libssh2/libssh2.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://libssh2.org/download/libssh2-\(versionString).tar.gz")
    }

    let cryptoDep: PackageDependency
    switch crypto {
    case .openssl: cryptoDep = .runTime(Openssl.self)
    case .gcrypt:  cryptoDep = .runTime(Gcrypt.self)
//    case .mbedtls: cryptoDep = .runTime(Mbedtls.self)
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        cryptoDep,
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
        cmakeOnFlag(false, "LINT"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeDefineFlag(crypto.option, "CRYPTO_BACKEND"),
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
        cmakeOnFlag(false, "BUILD_EXAMPLES"),
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

  enum CryptoBackend: String, PackageFeature {
    case openssl
    case gcrypt
//    case mbedtls // only 2.* is supported

    var option: String {
      switch self {
      case .openssl: return "OpenSSL"
      case .gcrypt:  return "Libgcrypt"
//      case .mbedtls: return "mbedTLS"
      }
    }
  }
}

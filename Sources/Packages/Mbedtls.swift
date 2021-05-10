import BuildSystem

public struct Mbedtls: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.26.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .tvOS, .tvSimulator, .watchOS, .watchSimulator:
      // fork() is not supported
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/ARMmbed/mbedtls.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/ARMmbed/mbedtls/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    // enable pthread
    try replace(contentIn: "include/mbedtls/config.h", matching: "//#define MBEDTLS_THREADING_PTHREAD", with: "#define MBEDTLS_THREADING_PTHREAD")
    try replace(contentIn: "include/mbedtls/config.h", matching: "//#define MBEDTLS_THREADING_C", with: "#define MBEDTLS_THREADING_C")

    try env.inRandomDirectory { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildStatic, "USE_STATIC_MBEDTLS_LIBRARY"),
        cmakeOnFlag(env.libraryType.buildShared, "USE_SHARED_MBEDTLS_LIBRARY"),
        cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(true, "LINK_WITH_PTHREAD"),
        cmakeOnFlag(env.strictMode, "ENABLE_TESTING"),
        cmakeOnFlag(true, "ENABLE_ZLIB_SUPPORT"),
        cmakeOnFlag(true, "ENABLE_PROGRAMS")
      )
      /*
       dependency:
       tls -> x509 & crypto
       x509 -> crypto
       */
      try env.make(toolType: .ninja)
      if env.canRunTests {
        try env.make(toolType: .ninja, "test")
      }
      try env.make(toolType: .ninja, "install")
    }

  }
}

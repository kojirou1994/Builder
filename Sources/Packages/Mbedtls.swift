import BuildSystem

public struct Mbedtls: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.6.0"
  }

  private func isLegacyVer(_ ver: PackageVersion) -> Bool {
    ver < "3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.system {
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
        .buildTool(Python.self),
        isLegacyVer(order.version) ? .runTime(Zlib.self) : nil,
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    // requirement: pip3 install --user jinja2 jsonschema

    try context.launch("pip3", ["install", "jinja2", "jsonschema"])

    let isLegacy = isLegacyVer(context.order.version)

    let configFilename = isLegacy ?  "config" : "mbedtls_config"

    let configPath = "include/mbedtls/\(configFilename).h"

    // enable pthread
    let featureMacros: [String?] = [
      "MBEDTLS_THREADING_PTHREAD",
      "MBEDTLS_THREADING_C",
      context.order.arch.isX86 ? "MBEDTLS_HAVE_SSE2" : nil,
      "MBEDTLS_SHA256_USE_A64_CRYPTO_IF_PRESENT",
      "MBEDTLS_SSL_DTLS_SRTP",
    ]

    try featureMacros
      .compactMap { $0 }
      .forEach { try replace(contentIn: configPath, matching: "//#define \($0)", with: "#define \($0)") }

    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildStatic, "USE_STATIC_MBEDTLS_LIBRARY"),
        cmakeOnFlag(context.libraryType.buildShared, "USE_SHARED_MBEDTLS_LIBRARY"),
        cmakeDefineFlag(context.dependencyMap[Python.self], "Python3_ROOT_DIR"),
        cmakeOnFlag(true, "LINK_WITH_PTHREAD"),
        cmakeOnFlag(context.strictMode, "ENABLE_TESTING"),
        isLegacy ? cmakeOnFlag(true, "ENABLE_ZLIB_SUPPORT") : nil,
        cmakeOnFlag(true, "ENABLE_PROGRAMS")
      )
      /*
       dependency:
       tls -> x509 & crypto
       x509 -> crypto
       */
      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }

  }
}

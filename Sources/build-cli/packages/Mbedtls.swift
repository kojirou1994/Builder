import BuildSystem

struct Mbedtls: Package {
  var defaultVersion: PackageVersion {
    .stable("2.25.0")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/ARMmbed/mbedtls/archive/refs/heads/development.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/ARMmbed/mbedtls/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  func supports(target: BuildTriple) -> Bool {
    switch target.system {
    case .tvOS, .tvSimulator, .watchOS, .watchSimulator:
      // fork() is not supported
      return false
    default:
      return true
    }
  }

  func build(with env: BuildEnvironment) throws {

    // enable pthread
    try replace(contentIn: "include/mbedtls/config.h", matching: "//#define MBEDTLS_THREADING_PTHREAD", with: "#define MBEDTLS_THREADING_PTHREAD")
    try replace(contentIn: "include/mbedtls/config.h", matching: "//#define MBEDTLS_THREADING_C", with: "#define MBEDTLS_THREADING_C")

    try env.changingDirectory("build-wokring") { _ in
      /*
       // Explicitly link mbed TLS library to pthread.
       LINK_WITH_PTHREAD:BOOL=OFF

       // Explicitly link mbed TLS library to trusted_storage.
       LINK_WITH_TRUSTED_STORAGE:BOOL=OFF

       // Compiler warnings treated as errors
       MBEDTLS_FATAL_WARNINGS:BOOL=ON

       // Allow unsafe builds. These builds ARE NOT SECURE.
       UNSAFE_BUILD:BOOL=OFF

       // Build mbed TLS with the pkcs11-helper library.
       USE_PKCS11_HELPER_LIBRARY:BOOL=OFF
       */
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildStatic, "USE_STATIC_MBEDTLS_LIBRARY", defaultEnabled: true),
        cmakeOnFlag(env.libraryType.buildShared, "USE_SHARED_MBEDTLS_LIBRARY", defaultEnabled: false),

        cmakeOnFlag(false, "ENABLE_TESTING"),
        cmakeOnFlag(true, "ENABLE_ZLIB_SUPPORT"),
        cmakeOnFlag(false, "ENABLE_PROGRAMS")
      )
      /*
       dependency:
       tls -> x509 & crypto
       x509 -> crypto
       */
      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }

  }
}

import BuildSystem

struct Zstd: Package {
  var defaultVersion: PackageVersion {
    .stable("1.4.9")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/facebook/zstd/archive/refs/heads/dev.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/facebook/zstd/archive/refs/tags/v\(version).tar.gz")
  }

  /*
   // Choose the type of build.
   CMAKE_BUILD_TYPE:STRING=Release

   // Executable file format
   CMAKE_EXECUTABLE_FORMAT:STRING=MACHO

   // Install path prefix, prepended onto install directories.
   CMAKE_INSTALL_PREFIX:PATH=/usr/local

   // Build architectures for OSX
   CMAKE_OSX_ARCHITECTURES:STRING=

   // Minimum OS X version to target for deployment (at runtime); newer APIs weak linked. Set to empty string for default value.
   CMAKE_OSX_DEPLOYMENT_TARGET:STRING=

   // The product will be built against the headers and libraries located inside the indicated SDK.
   CMAKE_OSX_SYSROOT:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX11.1.sdk

   // BUILD CONTRIB
   ZSTD_BUILD_CONTRIB:BOOL=ON

   // BUILD PROGRAMS
   ZSTD_BUILD_PROGRAMS:BOOL=ON

   // BUILD TESTS
   ZSTD_BUILD_TESTS:BOOL=OFF

   // LEGACY SUPPORT
   ZSTD_LEGACY_SUPPORT:BOOL=OFF

   // PROGRAMS LINK SHARED
   ZSTD_PROGRAMS_LINK_SHARED:BOOL=OFF
   */
  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build/cmake/build", block: { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "ZSTD_LZ4_SUPPORT"),
        cmakeOnFlag(true, "ZSTD_LZMA_SUPPORT"),
        cmakeOnFlag(true, "ZSTD_ZLIB_SUPPORT"),
        cmakeOnFlag(env.libraryType.buildStatic, "ZSTD_BUILD_STATIC"),
        cmakeOnFlag(env.libraryType.buildShared, "ZSTD_BUILD_SHARED"),
        cmakeOnFlag(false, "ZSTD_BUILD_PROGRAMS"),
        "-G", "Ninja"
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    })
  }
}

import BuildSystem

public struct Brotli: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.0.9")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/google/brotli/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/google/brotli/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {

//    try replace(contentIn: "CMakeLists.txt",
//                matching: "cmake_minimum_required(VERSION 2.8.6)",
//                with: "cmake_minimum_required(VERSION 3.0)")

    try env.changingDirectory("building") { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
//        cmakeOnFlag(false, "CMAKE_MACOSX_RPATH"),
//        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_RPATH"),
        nil
      )

      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }
}

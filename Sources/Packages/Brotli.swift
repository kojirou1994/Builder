import BuildSystem

public struct Brotli: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.9"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/google/brotli/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/google/brotli/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {

//    try replace(contentIn: "CMakeLists.txt",
//                matching: "cmake_minimum_required(VERSION 2.8.6)",
//                with: "cmake_minimum_required(VERSION 3.0)")

    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
//        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_RPATH"),
//        cmakeOnFlag(true, "CMAKE_BUILD_WITH_INSTALL_RPATH"),
        nil
      )

      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }
}

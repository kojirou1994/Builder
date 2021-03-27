import BuildSystem

public struct Cmake: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("3.20.0")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/Kitware/CMake/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/Kitware/CMake/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build") { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "SPHINX_HTML"),
        cmakeOnFlag(true, "SPHINX_MAN"),
        cmakeDefineFlag(env.dependencyMap["sphinx-doc"].bin.appendingPathComponent("sphinx-build").path, "SPHINX_EXECUTABLE")
      )

      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .blend(packages: [], brewFormulas: ["cmake", "sphinx-doc"])
  }

}

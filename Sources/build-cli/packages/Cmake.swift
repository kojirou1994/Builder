import BuildSystem

struct Cmake: Package {
  var defaultVersion: PackageVersion {
    .stable("3.20.0")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/Kitware/CMake/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/Kitware/CMake/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
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

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .blend(packages: [], brewFormulas: ["cmake", "sphinx-doc"])
  }

}

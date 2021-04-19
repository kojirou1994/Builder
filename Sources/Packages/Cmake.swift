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
    try env.changingDirectory(env.randomFilename) { _ in
      try env.launch(
        path: "../bootstrap",
        "--prefix=\(env.prefix.root.path)",
//        --no-system-libs
        "--parallel=\(env.parallelJobs ?? 8)",
//        --datadir=/share/cmake
//        --docdir=/share/doc/cmake
//        --mandir=/share/man
//        --sphinx-build=#{Formula["sphinx-doc"].opt_bin}/sphinx-build
//        --sphinx-html
//        --sphinx-man

//        on_macos do
//        args += %w[
        "--system-zlib",
        "--system-bzip2",
        "--system-curl"
//        cmakeOnFlag(true, "SPHINX_HTML"),
//        cmakeOnFlag(true, "SPHINX_MAN"),
//        cmakeDefineFlag(env.dependencyMap["sphinx-doc"].bin.appendingPathComponent("sphinx-build").path, "SPHINX_EXECUTABLE")
      )

      try env.make()

      try env.make("install")
    }
  }

}

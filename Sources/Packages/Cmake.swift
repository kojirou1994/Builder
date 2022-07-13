import BuildSystem

public struct Cmake: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.23.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/Kitware/CMake/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/Kitware/CMake/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(source: source, supportedLibraryType: nil)
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.launch(
        path: "../bootstrap",
        "--prefix=\(context.prefix.root.path)",
//        --no-system-libs
        "--parallel=\(context.parallelJobs ?? 8)",
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
//        cmakeDefineFlag(context.dependencyMap["sphinx-doc"].bin.appendingPathComponent("sphinx-build").path, "SPHINX_EXECUTABLE")
      )

      try context.make()

      try context.make("install")
    }
  }

}

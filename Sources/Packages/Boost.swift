import BuildSystem

public struct Boost: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.83.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/boostorg/boost.git", requirement: .branch("master"))
    case .stable(let version):
      source = .tarball(url: "https://boostorg.jfrog.io/artifactory/main/release/\(version.toString())/source/boost_\(version.toString(versionSeparator: "_")).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Icu4c.self),
        .runTime(Bzip2.self),
        .runTime(Zlib.self),
        .runTime(Zstd.self),
        .runTime(Xz.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "boostcpp.jam", matching: "<base> <threading> <runtime> <arch-and-model>", with: "<base> <threading> <runtime>")

    try context.launch(
      path: "./bootstrap.sh",
      "--prefix=\(context.prefix.root.path)",
      "--without-libraries=python",
      "--without-libraries=mpi",
      "--with-icu=\(context.dependencyMap[Icu4c.self].root.path)"
    )

    try context.launch(
      path: "./b2",
      "--prefix=\(context.prefix.root.path)",
      "--libdir=\(context.prefix.lib.path)",
      "-d2",
//      "--build-type=complete", /* useless */
      "--layout=tagged",
      "-j\(context.parallelJobs ?? 8)",
      "install",
      "threading=multi,single",
      "link=\(context.libraryType.link)",
      "-sICU_PATH=\(context.dependencyMap[Icu4c.self].root.path)",
      "-sZLIB_INCLUDE=\(context.dependencyMap[Zlib.self].include.path)",
      "-sZLIB_LIBPATH=\(context.dependencyMap[Zlib.self].lib.path)",
      "-sBZIP2_INCLUDE=\(context.dependencyMap[Bzip2.self].include.path)",
      "-sBZIP2_LIBPATH=\(context.dependencyMap[Bzip2.self].lib.path)",
      "-sZSTD_INCLUDE=\(context.dependencyMap[Zstd.self].include.path)",
      "-sZSTD_LIBPATH=\(context.dependencyMap[Zstd.self].lib.path)",
      "-sLZMA_INCLUDE=\(context.dependencyMap[Xz.self].include.path)",
      "-sLZMA_LIBPATH=\(context.dependencyMap[Xz.self].lib.path)"
    )

    try context.fixDylibsID()
  }
}

fileprivate extension PackageLibraryBuildType {
  var link: String {
    if self == .all {
      return "shared,static"
    }
    return rawValue
  }
}

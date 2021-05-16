import BuildSystem

public struct Boost: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.76.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/boostorg/boost.git", requirement: .branch("master"))
    case .stable(let version):
      source = .tarball(url: "https://dl.bintray.com/boostorg/release/\(version.toString())/source/boost_\(version.toString(versionSeparator: "_")).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Icu4c.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch(path: "bootstrap.sh",
                   "--prefix=\(context.prefix.root.path)",
                   "--libdir=\(context.prefix.lib.path)",
                   "--without-libraries=\(["python", "mpi"].joined(separator: ","))",
                   "--with-icu=\(context.dependencyMap[Icu4c.self].root.path)"
    )
    try context.launch(path: "b2", "headers")
    try context.launch(path: "b2",
                   "--prefix=\(context.prefix.root.path)",
                   "--libdir=\(context.prefix.lib.path)",
                   "-d2",
                   "-j\(context.parallelJobs ?? 8)",
                   "install",
//                   "threading=multi,single",
                   "link=\(context.libraryType.link)"
    )
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

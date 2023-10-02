import BuildSystem

public struct Iperf3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.15.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/esnet/iperf.git", requirement: .branch("master"))
    case .stable(let version):
      source = .tarball(url: "https://github.com/esnet/iperf/archive/refs/tags/\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(Openssl.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch(path: "bootstrap.sh")
    try context.configure(
      context.libraryType.sharedConfigureFlag,
      context.libraryType.staticConfigureFlag,
      "--with-openssl=\(context.dependencyMap[Openssl.self])"
    )

    try context.make("clean")
    try context.make("install")
  }

}

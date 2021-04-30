import BuildSystem

public struct Iperf3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.9"
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

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "bootstrap.sh")
    try env.configure(
      env.libraryType.sharedConfigureFlag,
      env.libraryType.staticConfigureFlag,
      "--with-openssl=\(env.dependencyMap[Openssl.self])"
    )

    try env.make("clean")
    try env.make("install")
  }

}

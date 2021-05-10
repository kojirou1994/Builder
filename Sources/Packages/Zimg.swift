import BuildSystem

public struct Zimg: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "3.0.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/sekrit-twc/zimg.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .library(name: "zimg", headers: ["zimg.h"])
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(env.strictMode, "testapp"),
      configureEnableFlag(env.strictMode, "example")
    )

    try env.make()

    if env.canRunTests {
      try env.make("check")
    }

    try env.make("install")
  }
}

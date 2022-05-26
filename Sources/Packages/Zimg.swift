import BuildSystem

public struct Zimg: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "3.0.4"
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

  public func build(with context: BuildContext) throws {
    try context.autogen()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(context.strictMode, "testapp"),
      configureEnableFlag(context.strictMode, "example")
    )

    try context.make()

    if context.canRunTests {
      try context.make("check")
    }

    try context.make("install")
  }
}

import BuildSystem

public struct Libev: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "4.33"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://dist.schmorp.de/libev/Attic/libev-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .library(name: "ev", headers: [
          "ev.h",
//          "ev++.h",
          "event.h",
        ]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }
}

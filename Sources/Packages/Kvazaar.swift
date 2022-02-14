import BuildSystem

public struct Kvazaar: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.1"
  }

  private func asmEnabled(_ order: PackageOrder) -> Bool {
    order.arch.isX86
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/ultravideo/kvazaar.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/ultravideo/kvazaar/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        asmEnabled(order) ? .runTime(Yasm.self) : nil,
      ],
      products: [
        .bin("kvazaar"),
        .library(name: "kvazaar", headers: ["kvazaar.h"])
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()
    try context.fixAutotoolsForDarwin()

    try context.configure(
      context.libraryType.sharedConfigureFlag,
      context.libraryType.staticConfigureFlag,
      configureEnableFlag(asmEnabled(context.order), "asm")
    )

    try context.make("install")
  }

}

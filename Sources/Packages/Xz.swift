import BuildSystem

public struct Xz: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.4.4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/tukaani-project/xz.git")
    case .stable(let version):
      source = .tarball(url: "https://tukaani.org/xz/xz-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(Gettext.self),
      ],
      products: [
        .bin("xzdec"),
        .bin("lzmadec"),
        .bin("lzmainfo"),
        .bin("xz"),
        .library(name: "lzma", headers: ["lzma", "lzma.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    /*
     If po4a is missing, autogen.sh will fail at the end but the package can be built normally still;
     only the translated documentation will be missing.
     */
    try? context.autogen()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }

}

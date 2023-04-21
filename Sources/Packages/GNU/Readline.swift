import BuildSystem

public struct Readline: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "8.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let patches: [PackagePatch]
      switch (version.major, version.minor) {
      case (8, 2):
        patches = [
          .remote(url: "https://ftp.gnu.org/gnu/readline/readline-8.2-patches/readline82-001", sha256: nil, tool: .patch(stripCount: 0))
        ]
      default: patches = []
      }
      source = .tarball(url: "https://ftp.gnu.org/gnu/readline/readline-\(version.toString(includeZeroPatch: false)).tar.gz", patches: patches)
    }

    return .init(
      source: source,
      dependencies: [
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.configure(
      context.order.libraryType.staticConfigureFlag,
      context.order.libraryType.sharedConfigureFlag,
      configureWithFlag(true, "curses"),
      nil
    )

    try context.make("install", "SHLIB_LIBS=-lcurses")
  }
}

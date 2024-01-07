import BuildSystem

public struct Sqlite: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.44.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://sqlite.org/2023/sqlite-autoconf-\(String(format: "%d%02d%02d", version.major, version.minor, version.patch))00.tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Zlib.self),
        .optional(.runTime(Readline.self), when: !order.system.isApple),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    [
      "-DSQLITE_ENABLE_COLUMN_METADATA=1",
      "-DSQLITE_MAX_VARIABLE_NUMBER=250000",
      "-DSQLITE_ENABLE_RTREE=1",
      "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1",
      "-DSQLITE_ENABLE_JSON1=1",
    ].forEach { context.environment.append($0, for: .cppflags) }

    try context.configure(
      context.order.libraryType.staticConfigureFlag,
      context.order.libraryType.sharedConfigureFlag,
      configureWithFlag(context.order.system.isApple, "editline"),
      configureWithFlag(!context.order.system.isApple, "readline"),
      configureWithFlag(true, "session"),
      configureEnableFlag(context.order.libraryType == .static, "static-shell"),
      nil
    )

    try context.make("install")
  }
}

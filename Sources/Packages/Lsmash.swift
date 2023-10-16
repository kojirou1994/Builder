import BuildSystem

public struct Lsmash: Package {

  public init() {}

  @Flag()
  var enableCli: Bool = false

  public var defaultVersion: PackageVersion {
    "2.14.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/l-smash/l-smash/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/l-smash/l-smash/archive/refs/tags/v\(version.toString(includeZeroPatch: true)).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {

    #if os(macOS)
    try replace(contentIn: "configure", matching: ",--version-script,liblsmash.ver", with: "")
    #endif

    try context.launch(
      path: "./configure",
      "--prefix=\(context.prefix.root.path)",
      "--cc=\(context.cc)",
      "--extra-cflags=\(context.environment[.cflags])",
      configureEnableFlag(context.libraryType.buildStatic, "static", defaultEnabled: true),
      configureEnableFlag(context.libraryType.buildShared, "shared", defaultEnabled: false)
    )

    try context.make()

    try context.make(enableCli ? "install" : "install-lib")
  }

  public var tag: String {
    enableCli ? "CLI" : ""
  }

}

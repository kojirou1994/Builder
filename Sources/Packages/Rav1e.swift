import BuildSystem

public struct Rav1e: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.4.1"
  }

  /*
   success targets:
   aarch64-apple-darwin
   aarch64-apple-ios
   x86_64-apple-darwin
   */
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS, .linuxGNU:
      break
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/xiph/rav1e/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/xiph/rav1e/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Nasm.self),
        .cargo(["cargo-c"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    // TODO: add BUILD_TESTING
    /*
     system "cargo", "install", *std_cargo_args
     system "cargo", "cinstall", "--prefix", prefix
     */
    try env.launch("cargo", "install", "--root",
                   env.prefix.root.path,
                   "--target", env.order.target.rustTripleString,
                   "--path", ".")
    var types: [String?] = []
    switch env.libraryType {
    case .shared, .static:
      types.append("--library-type")
      types.append(env.libraryType == .shared ? "cdylib" : "staticlib")
    default: break
    }
    try env.launch("cargo",
                   ["cinstall", "--prefix",
                    env.prefix.root.path,
                    "--target", env.order.target.rustTripleString] + types)
  }


}

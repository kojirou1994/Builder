import BuildSystem

public struct Rav1e: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.7.0"
  }

  /*
   success targets:
   aarch64-apple-darwin
   aarch64-apple-ios
   x86_64-apple-darwin
   */
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.system {
    case .macOS, .linuxGNU:
      break
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/rav1e.git")
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

  public func build(with context: BuildContext) throws {
    // TODO: add BUILD_TESTING
    try context.launch("cargo", "install", "--root",
                   context.prefix.root.path,
                   "--target", context.order.target.rustTripleString,
                   "--path", ".")
    var types: [String?] = []
    switch context.libraryType {
    case .shared, .static:
      types.append("--library-type")
      types.append(context.libraryType == .shared ? "cdylib" : "staticlib")
    default: break
    }
    try context.launch("cargo",
                   ["cinstall", "--prefix",
                    context.prefix.root.path,
                    "--target", context.order.target.rustTripleString] + types)
  }


}

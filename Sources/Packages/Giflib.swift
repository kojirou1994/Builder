import BuildSystem

public struct Giflib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
//    .stable("5.1.4")
    "5.2.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/giflib/giflib-\(version.toString()).tar.gz",
                        patches: [.remote(url: "https://sourceforge.net/p/giflib/bugs/_discuss/thread/4e811ad29b/c323/attachment/Makefile.patch", sha256: "")])
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {
    // parallel not supported
    let prefix = "PREFIX=\(context.prefix.root.path)"
    try context.launch("make", "install", prefix)
    try context.launch("make", "install-man", prefix)

    try context.autoRemoveUnneedLibraryFiles()
    try context.fixDylibsID()
  }

}

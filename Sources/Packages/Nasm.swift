import BuildSystem

public struct Nasm: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.15.05"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      var verStr = "\(version.major).\(String(format: "%02d", version.minor))"
      if version.patch != 0 {
        verStr.append(".\(String(format: "%02d", version.patch))")
      }
      source = .tarball(url: "https://www.nasm.us/pub/nasm/releasebuilds/\(verStr)/nasm-\(verStr).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
//      dependencies: .brew(["asciidoc", "autoconf", "automake", "xmlto"]),
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()
    try context.configure()
//    try context.make("rdf")
    try context.make("install")//, "install_rdf")
  }
}

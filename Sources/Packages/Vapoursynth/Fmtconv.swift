import BuildSystem

public struct Fmtconv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "23"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz", patches: [.remote(url: "https://github.com/EleonoreMizo/fmtconv/commit/5e0340d35e4dfd58209fd85c51c6e348840014c3.patch", sha256: "")])
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory("build/unix") { _ in
      try context.autogen()

      try context.configure(
        
      )

      try context.make()
      try context.make("install")
    }
  }
}

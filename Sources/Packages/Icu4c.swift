import BuildSystem

public struct Icu4c: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "69.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/unicode-org/icu/archive/refs/tags/release-\(version.toString(includeZeroMinor: false, includeZeroPatch: false, versionSeparator: "-")).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .brew(["autoconf", "automake", "libtool"])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("icu4c/source", block: { _ in
      try env.autoreconf()

      try env.configure(
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        "--disable-samples",
        "--disable-tests",
        "--with-library-bits=64"
      )

      try env.make()
      try env.make("install")
    })
  }

}

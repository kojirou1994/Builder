import BuildSystem

public struct Freetype: Package {

  public var defaultVersion: PackageVersion {
    "2.10.4"
  }

  @Flag
  var withHarfbuzz: Bool = false

  public var tag: String {
    (withHarfbuzz ? "harfbuzz" : "")
  }

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://downloads.sourceforge.net/project/freetype/freetype2/\(versionString)/freetype-\(versionString).tar.xz")
    }

    return .init(
      source: source,
      dependencies:
        .blend(
          packages: [
            .init(Png.self),
            //      .init(Brotli.self), // google shit
            withHarfbuzz ? .init(Harfbuzz.self) : nil
          ],
          brewFormulas: [
//            "autoconf", "automake", "libtool"
          ])
        )
  }

  public func build(with env: BuildEnvironment) throws {

//    try env.autogen()

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--enable-freetype-config",
      configureWithFlag(true, "png"),
      configureWithFlag(withHarfbuzz, "harfbuzz"),
      configureWithFlag(false, "brotli")
    )

    try env.make()
    try env.make("install")
  }
}

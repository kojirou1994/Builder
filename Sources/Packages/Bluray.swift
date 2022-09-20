import BuildSystem

public struct Bluray: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://download.videolan.org/videolan/libbluray/\(version.toString())/libbluray-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        freetype ? .runTime(Freetype.self) : nil,
        .runTime(Xml2.self),
      ]
    )
  }

  /*
   Summary:
   --------
   BD-J type:                     j2se
   build JAR:                     no
   Font support (freetype2):      yes
   Use system fonts (fontconfig): no
   Metadata support (libxml2):    yes
   External libudfread:           no
   Build examples:                no
   */

  public func build(with context: BuildContext) throws {
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "examples"),
      configureEnableFlag(false, "doxygen-doc"),
      configureEnableFlag(false, "doxygen-dot"),
      configureEnableFlag(false, "doxygen-html"),
      configureEnableFlag(false, "doxygen-ps"),
      configureEnableFlag(false, "doxygen-pdf"),
      configureEnableFlag(false, "bdjava-jar"),
      configureWithFlag(freetype, "freetype"),
      configureWithFlag(false, "fontconfig")
    )

    try context.make()
    try context.make("install")
  }

  @Flag(inversion: .prefixedEnableDisable)
  var freetype: Bool = true

  public var tag: String {
    [
      freetype ? "" : "no_freetype"
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "-")
  }
}

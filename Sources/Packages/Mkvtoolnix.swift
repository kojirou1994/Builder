import BuildSystem

public struct Mkvtoolnix: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "56.1.0"
  }

  /*
   macOS app:
   https://mkvtoolnix.download/macos/MKVToolNix-56.1.0.dmg

   */
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Vorbis.self),
        .runTime(Ebml.self),
        .runTime(Matroska.self),
        .runTime(Pugixml.self),
        .runTime(Pcre2.self),
        .runTime(Fmt.self),
        .runTime(Flac.self),
        .runTime(Jpcre2.self),
        .runTime(Gettext.self),
        .runTime(Boost.self),
        .runTime(NlohmannJson.self),
        .runTime(Zlib.self),
        .runTime(Dvdread.self),
        .brew(["docbook-xsl"], requireLinked: false),
      ]
    )
  }
  
  public func build(with context: BuildContext) throws {

    try context.autogen()

    try context.configure(
      configureEnableFlag(false, "qt"),
      "--with-docbook-xsl-root=\(context.dependencyMap["docbook-xsl"].appending("docbook-xsl").path)"
    )

    try context.launch("rake", context.parallelJobs.map { "-j\($0)" } )
    try context.launch("rake", "install")
  }

}

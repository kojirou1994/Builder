import BuildSystem

public struct Mkvtoolnix: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "58"
  }

  /*
   macOS app:
   https://mkvtoolnix.download/macos/MKVToolNix-56.1.0.dmg

   */
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://gitlab.com/mbunkus/mkvtoolnix.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-\(versionString).tar.xz")
    }

    source.patches.append(.remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/mkvtoolnix/0001-disable-file-cache.patch", sha256: nil))
    source.patches.append(.remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/mkvtoolnix/0002-add-fcntl-header.patch", sha256: nil))

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
        .runTime(Boost.self),
        .runTime(NlohmannJson.self),
        .runTime(Zlib.self),
        .runTime(Dvdread.self),
        .runTime(Libiconv.self),
//        .brew(["docbook-xsl"], requireLinked: false),
      ],
      supportedLibraryType: nil
    )
  }
  
  public func build(with context: BuildContext) throws {

    try context.autogen()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, "qt"),
      "--with-docbook-xsl-root=/opt/local/share/xsl/docbook-xsl-nons"
    )

    try context.launch("rake", context.parallelJobs.map { "-j\($0)" } )
    try context.launch("rake", "install")
  }

}

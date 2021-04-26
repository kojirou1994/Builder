import BuildSystem

public struct Mkvtoolnix: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "56.1.0"
  }

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
      dependencies: PackageDependencies(
        packages: [
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
        ],
        otherPackages: [.brew(["docbook-xsl"], requireLinked: false)])
    )
  }
  
  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "autogen.sh")

//    try replace(contentIn: "configure", matching: "LINK_STATICALLY=\" -static \"", with: "")

    try env.configure(
      configureWithFlag(false, "qt"),
      "--with-docbook-xsl-root=\(env.dependencyMap["docbook-xsl"].appending("docbook-xsl").path)"
    )

    try env.launch("rake", "-j8")
    try env.launch("rake", "install")
  }

}

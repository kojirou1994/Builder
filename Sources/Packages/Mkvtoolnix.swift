import BuildSystem

public struct Mkvtoolnix: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "55.0.0"
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
      dependencies:
        .blend(packages: [
                .init(Vorbis.self), .init(Ebml.self),
                .init(Matroska.self), .init(Pugixml.self),
                .init(Pcre2.self), .init(Fmt.self),
                .init(Flac.self), .init(Jpcre2.self)],
               brewFormulas: ["docbook-xsl"])
    )
  }
  
  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "autogen.sh")

    try env.configure(
      env.libraryType.staticConfigureFlag,
//      env.libraryType.sharedConfigureFlag,
      "--without-boost",
      "--with-qt=no",
      "--with-docbook-xsl-root=\(env.dependencyMap["docbook-xsl"].appending("docbook-xsl").path)"
    )

    try env.launch("rake", "-j8")
    try env.launch("rake", "install")
  }

}

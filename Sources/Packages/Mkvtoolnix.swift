import BuildSystem

struct Mkvtoolnix: Package {
  var defaultVersion: PackageVersion {
    .stable("55.0.0")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    return .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-\(version.toString()).tar.xz")
  }
  
  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "autogen.sh")

    try env.configure(
      env.libraryType.staticConfigureFlag,
//      env.libraryType.sharedConfigureFlag,
//      "--without-boost",
      "--with-qt=no",
      "--with-docbook-xsl-root=\(env.dependencyMap["docbook-xsl"].appending("docbook-xsl").path)"
    )

    try env.launch("rake", "-j8")
    try env.launch("rake", "install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .blend(packages: [
            .init(Vorbis.self), .init(Ebml.self),
            .init(Matroska.self), .init(Pugixml.self),
            .init(Pcre2.self), .init(Fmt.self),
            .init(Flac.self), .init(Jpcre2.self)],
           brewFormulas: ["docbook-xsl"])
  }
}

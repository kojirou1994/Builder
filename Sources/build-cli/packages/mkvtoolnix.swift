import BuildSystem

struct Mkvtoolnix: Package {
  var version: PackageVersion {
    .stable("52.0.0")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-\(v).tar.xz")
    default:
      return nil
    }
  }
  
  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "autogen.sh")

    try env.configure(
//      env.libraryType.staticConfigureFlag,
//      env.libraryType.sharedConfigureFlag,
//      "--without-boost",
      "--with-qt=no",
      "--with-docbook-xsl-root=\(env.dependencyMap["docbook-xsl"].appending("docbook-xsl").path)"
    )

    try env.launch("rake", "-j8")
    try env.launch("rake", "install")
  }

  var dependencies: PackageDependency {
    .blend(packages: [
            Vorbis.defaultPackage(), Ebml.defaultPackage(),
            Matroska.defaultPackage(), Pugixml.defaultPackage(),
            Pcre2.defaultPackage(), Fmt.defaultPackage(),
            Flac.defaultPackage(), Jpcre2.defaultPackage()],
           brewFormulas: ["docbook-xsl"])
  }
}

import BuildSystem

struct Mkvtoolnix: Package {
  func build(with builder: Builder) throws {
    try builder.launch(path: "autogen.sh")

    try builder.configure(
//      builder.settings.library.staticConfigureFlag,
//      builder.settings.library.sharedConfigureFlag,
//      "--without-boost",
      "--with-qt=no",
      "--with-docbook-xsl-root=/usr/local/opt/docbook-xsl/docbook-xsl"
    )

    try builder.launch("rake", "-j8")
    try builder.launch("rake", "install")
  }

  var source: PackageSource {
    .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-52.0.0.tar.xz")
  }

  var dependencies: [Package] {
    [Vorbis.defaultPackage(), Ebml.defaultPackage(), Matroska.defaultPackage(),
     Pugixml.defaultPackage(), Pcre2.defaultPackage(), Fmt.defaultPackage(),
     Flac.defaultPackage(), Jpcre2.defaultPackage()]
  }
}

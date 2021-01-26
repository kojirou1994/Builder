import BuildSystem

struct Freetype: Package {
  func build(with env: BuildEnvironment) throws {

    try env.launch(path: "autogen.sh")

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--enable-freetype-config",
      "--without-harfbuzz",
      "--without-brotli"
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.sourceforge.net/project/freetype/freetype2/2.10.4/freetype-2.10.4.tar.xz")
  }

  var dependencies: PackageDependency {
    .packages(Png.defaultPackage())
  }
}

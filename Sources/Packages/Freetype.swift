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

  var defaultVersion: PackageVersion {
    .stable("2.10.4")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    let versionString = version.toString(includeZeroPatch: false)
    return .tarball(url: "https://downloads.sourceforge.net/project/freetype/freetype2/\(versionString)/freetype-\(versionString).tar.xz")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Png.self))
  }
}

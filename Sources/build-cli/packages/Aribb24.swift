import BuildSystem

struct Aribb24: Package {
  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "bootstrap")
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/nkoriyama/aribb24/archive/v1.0.3.tar.gz", filename: "aribb24-1.0.3.tar.gz")
  }

  var dependencies: PackageDependency {
    .packages(Png.defaultPackage)
  }
}

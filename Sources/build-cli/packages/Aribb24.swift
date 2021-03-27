import BuildSystem

struct Aribb24: Package {

  var defaultVersion: PackageVersion {
    .stable("1.0.3")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/nkoriyama/aribb24/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "bootstrap")
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Png.self))
  }
}

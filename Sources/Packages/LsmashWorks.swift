import BuildSystem

struct LsmashWorks: Package {

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/VFR-maniac/L-SMASH-Works/archive/refs/heads/master.zip")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Lsmash.self))
  }

  func build(with env: BuildEnvironment) throws {

    try env.changingDirectory("VapourSynth", block: { _ in
      try env.configure(
      )

      try env.make()

      try env.make("install")
    })
  }

}

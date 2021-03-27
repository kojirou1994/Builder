import BuildSystem

public struct LsmashWorks: Package {
  public init() {}

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/VFR-maniac/L-SMASH-Works/archive/refs/heads/master.zip")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Lsmash.self))
  }

  public func build(with env: BuildEnvironment) throws {

    try env.changingDirectory("VapourSynth", block: { _ in
      try env.configure(
      )

      try env.make()

      try env.make("install")
    })
  }

}

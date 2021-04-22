import BuildSystem

public struct Ninja: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("1.10.2")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .make, 
        ".."
        /* -DBUILD_TESTING */
      )

      try env.make()

      try env.make("install")
    }
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Cmake.self))
  }

}

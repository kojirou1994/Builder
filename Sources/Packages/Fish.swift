import BuildSystem

public struct Fish: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("3.2.2")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    })
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/fish-shell/fish-shell/releases/download/\(version.toString())/fish-\(version.toString()).tar.xz")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Cmake.self, options: .init(buildTimeOnly: true)),
      .init(Pcre2.self),
      .init(Ninja.self)
    )
  }
}

import BuildSystem

public struct Fmtconv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "22"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build/unix", block: { _ in
      try env.autogen()

      try env.configure(
        
      )

      try env.make()
      try env.make("install")
    })
  }
}

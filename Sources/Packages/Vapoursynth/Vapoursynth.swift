/*
 need automake autoconf libtool
 pyenv prefix
 
 */

import BuildSystem

public struct Vapoursynth: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "53"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/vapoursynth/vapoursynth.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/vapoursynth/vapoursynth/archive/refs/tags/R\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .buildTool(Nasm.self),
        .runTime(Zimg.self),
        .pip(["cython"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")

    try env.launch("pip", "install", ".")
  }
}

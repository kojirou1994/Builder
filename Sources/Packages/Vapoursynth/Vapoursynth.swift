/*
 need automake autoconf libtool
 pyenv prefix
 
 */

import BuildSystem

public struct Vapoursynth: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "57"
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
        .runTime(Python.self),
      ],
      supportedLibraryType: .all
    )
  }

  public func build(with context: BuildContext) throws {
    // uninstall if installed
    try context.launch("pip3", "uninstall", "vapoursynth", "-y")

    try context.launch("pip3", "install", "cython")

    try context.autogen()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "python-module")
    )

    try context.make()
    try context.make("install")

    context.environment.append("-I\(context.prefix.include.path)", for: .cxxflags, .cflags)
    context.environment.append("-L\(context.prefix.lib.path)", for: .ldflags)

    try context.launch("pip3", "install", ".")

    return
  }
}

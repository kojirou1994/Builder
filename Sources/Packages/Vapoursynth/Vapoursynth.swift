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
        .pip(["cython"]),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    // uninstall if installed
    try context.launch("pip", "uninstall", "vapoursynth", "-y")

    try context.autogen()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")

    // or manually install to site-packages:
    do {
      let sitePackagesDirectory = try context.external.pythonSitePackagesDirectoryURL()!
      let pythonStr = sitePackagesDirectory.pathComponents.dropLast().last!
      let soFilename = "vapoursynth.so"
      let src = context.prefix.appending("lib", pythonStr, "site-packages", soFilename)
      let dst = sitePackagesDirectory.appendingPathComponent(soFilename)
      try? context.removeItem(at: dst)

      try context.createSymbolicLink(at: dst, withDestinationURL: src)
    }
  }
}

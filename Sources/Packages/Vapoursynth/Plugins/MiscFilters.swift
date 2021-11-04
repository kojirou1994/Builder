import BuildSystem

public struct MiscFilters: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/vapoursynth/vs-miscfilters-obsolete/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/vapoursynth/vs-miscfilters-obsolete/archive/refs/tags/R\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try replace(contentIn: "src/miscfilters.cpp", matching: "#include <algorithm>", with: "#include <string>\n#include <algorithm>")
    
    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.make(toolType: .ninja, "install")
    }
  }
}

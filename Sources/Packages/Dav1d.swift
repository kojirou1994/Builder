import BuildSystem

public struct Dav1d: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://code.videolan.org/videolan/dav1d/-/archive/master/dav1d-master.tar.gz")
    case .stable(let version):
      source = .tarball(url: "https://code.videolan.org/videolan/dav1d/-/archive/\(version)/dav1d-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .optional(.buildTool(Nasm.self), when: order.arch.isX86),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.meson(
        "..",
        context.libraryType == .static ? "--default-library=static" : nil
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}

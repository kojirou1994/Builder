import BuildSystem

public struct Brotli: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.9"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/google/brotli/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/google/brotli/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
      )

      try context.make(toolType: .ninja)

      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
    if context.libraryType.buildStatic {
      try """
      libbrotlicommon-static.a
      libbrotlidec-static.a
      libbrotlienc-static.a
      """.split(separator: "\n")
        .forEach { filename in
          try context.moveItem(at: context.prefix.lib.appendingPathComponent(String(filename)),
                              to: context.prefix.lib.appendingPathComponent(String(filename.dropLast("-static.a".count)) + ".a"))
        }
    }
  }
}

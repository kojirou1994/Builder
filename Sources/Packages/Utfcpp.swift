import BuildSystem

public struct Utfcpp: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.1.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      // test required repo
      // https://github.com/nemtrif/utfcpp.git
      source = .tarball(url: "https://github.com/nemtrif/utfcpp/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      products: [
        .header("utf8cpp")
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "UTF8_SAMPLES"),
        cmakeOnFlag(false, "UTF8_TESTS")
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }

}

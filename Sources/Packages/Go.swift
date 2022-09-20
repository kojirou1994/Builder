import BuildSystem

public struct Go: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.19.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let systemString: String
    let archString: String

    switch order.system {
    case .macOS:
      systemString = "darwin"
    case .linuxGNU:
      systemString = "linux"
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    switch order.arch {
    case .arm64:
      archString = "arm64"
    case .x86_64:
      archString = "amd64"
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://golang.org/dl/go\(version.toString()).\(systemString)-\(archString).tar.gz")
    }

    return .init(
      source: source,
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "."), includingPropertiesForKeys: nil, options: [])
      .forEach { content in
        try context.moveItem(at: content, to: context.prefix.appending(content.lastPathComponent))
      }
  }

}

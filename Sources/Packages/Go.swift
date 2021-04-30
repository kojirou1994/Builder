import BuildSystem

public struct Go: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.16.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let systemString: String
    let archString: String

    switch order.target.system {
    case .macOS:
      systemString = "darwin"
    case .linuxGNU:
      systemString = "linux"
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    switch order.target.arch {
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

  public func build(with env: BuildEnvironment) throws {
    try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "."), includingPropertiesForKeys: nil, options: [])
      .forEach { content in
        try env.moveItem(at: content, to: env.prefix.appending(content.lastPathComponent))
      }
  }

}

import ArgumentParser
import Version

public struct PackageOrder: Codable {
  public init(version: PackageVersion, target: BuildTriple) {
    self.version = version
    self.target = target
  }

  public let version: PackageVersion
  public let target: BuildTriple
}

public enum PackageRecipeError: Error {
  case unsupportedVersion
  case unsupportedTarget
}

public struct PackageRecipe {

  public init(source: PackageSource,
              dependencies: PackageDependencies = .empty,
              supportsBitcode: Bool = true,
              products: [BuildProduct?] = [],
              supportedLibraryType: PackageLibraryBuildType? = .all) {
    self.source = source
    self.dependencies = dependencies
    self.supportsBitcode = supportsBitcode
    self.products = products.compactMap { $0 }
    self.supportedLibraryType = supportedLibraryType
  }

  public let source: PackageSource
  public let dependencies: PackageDependencies
  public let supportsBitcode: Bool
  public let products: [BuildProduct]
  public let supportedLibraryType: PackageLibraryBuildType?
}

public struct SystemPackage {
  public init(prefix: PackagePath, pkgConfigs: [SystemPackage.SystemPkgConfig]) {
    self.prefix = prefix
    self.pkgConfigs = pkgConfigs
  }

  let prefix: PackagePath
  let pkgConfigs: [SystemPkgConfig]

  public struct SystemPkgConfig {
    public init(name: String, content: String) {
      self.name = name
      self.content = content
    }

    let name: String
    let content: String
  }
}

/*
 version -> dependency & source & patch -> build
 */

public protocol Package: ParsableArguments, CustomStringConvertible, Encodable {

  static var name: String { get }

  var defaultVersion: PackageVersion { get }

  /// tag is used to generate version suffix
  var tag: String { get }

  /// This method must throw PackageRecipeError
  /// - Parameter order: information about the building
  func recipe(for order: PackageOrder) throws -> PackageRecipe

  func build(with env: BuildEnvironment) throws

  func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage?

}

public extension Package {

  init(_ initialize: (inout Self) -> Void) {
    self = Self.defaultPackage
    initialize(&self)
  }

  var buildInfo: String { "" }

  var tag: String { "" }

  var description: String {
    """
    Name: \(name)
    Default Version: \(defaultVersion)
    Source: (String(describing: packageSource(for: defaultVersion)))
    Dependencies:
    (dependencies(for: defaultVersion))
    Information:
    \(buildInfo)
    """
  }

  var defaultVersion: PackageVersion { .head }

  func encode(to encoder: Encoder) throws { }

  static var name: String {
    String(describing: Self.self).convertedToSnakeCase(separator: "-")
  }

  var name: String { Self.name }

  static var defaultPackage: Self {
    try! {
      do {
        return try parse([])
      } catch {
        assertionFailure("Package must have default settings.")
        throw BuilderError.invalidDefaultPackage(name: String(describing: Self.self))
      }
    }()
  }

  func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? { nil }

}

extension Package {
  var identifier: ObjectIdentifier {
    .init(Self.self)
  }
}

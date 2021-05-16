import ArgumentParser

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

  func build(with env: BuildContext) throws

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
    do {
      return try parse([])
    } catch {
      fatalError("Cannot get \(name)'s default package, check your code!")
    }
  }

  func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? { nil }

}

extension Package {
  var identifier: ObjectIdentifier {
    .init(Self.self)
  }
}

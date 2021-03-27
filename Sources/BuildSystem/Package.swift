import ArgumentParser
import Version

public protocol Package: ParsableArguments, CustomStringConvertible {

  static var name: String { get }
  
  var defaultVersion: PackageVersion { get }

  var products: [BuildProduct] { get }

  /// like a hash of a package
  var tag: String { get }
  /// string description of package building
  var buildInfo: String { get }

  var supportsBitcode: Bool { get }
  func supports(target: BuildTriple) -> Bool

  var headPackageSource: PackageSource? { get }
  func stablePackageSource(for version: Version) -> PackageSource?
  func dependencies(for version: PackageVersion) -> PackageDependencies

  func build(with env: BuildEnvironment) throws

}

public extension Package {

  var buildInfo: String { "" }

  var tag: String { "" }

  var description: String {
    """
    Name: \(name)
    Default Version: \(defaultVersion)
    Source: \(String(describing: packageSource(for: defaultVersion)))
    Dependencies:
    \(dependencies(for: defaultVersion))
    Information:
    \(buildInfo)
    """
  }

  var defaultVersion: PackageVersion { .head }

  var headPackageSource: PackageSource? { nil }
  func stablePackageSource(for version: Version) -> PackageSource? { nil }
  
  func dependencies(for version: PackageVersion) -> PackageDependencies { .empty }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return stablePackageSource(for: v)
    case .head:
      return headPackageSource
    }
  }

  var products: [BuildProduct] { [] }

  static var name: String {
    String(describing: Self.self).lowercased()
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

  var supportsBitcode: Bool { true }
  func supports(target: BuildTriple) -> Bool { true }
}

extension Package {
  var identifier: ObjectIdentifier {
    .init(Self.self)
  }
}

import ArgumentParser

public protocol Package: ParsableArguments, CustomStringConvertible {

  static var name: String { get }
  
  var version: PackageVersion { get }
  var source: PackageSource { get }
  var dependencies: PackageDependency { get }
  var products: [BuildProduct] { get }

  var tag: String { get }
  var buildInfo: String { get }

  var supportsBitcode: Bool { get }
  func supports(target: BuildTriple) -> Bool

  func packageSource(for version: PackageVersion) -> PackageSource?
  func build(with env: BuildEnvironment) throws

}

public extension Package {

  var buildInfo: String { "" }

  var version: PackageVersion {
    // guess version from source
//    fatalError("Unimplemented")
    return .stable("unknown-version")
  }

  var tag: String { "" }

  var description: String {
    """
    Name: \(name)
    Version: \(version)
    Source: \(source)
    Dependencies:
    \(dependencies)
    Information:
    \(buildInfo)
    """
  }

  var dependencies: PackageDependency {
    .empty
  }

  var products: [BuildProduct] { [] }

  static var name: String {
    String(describing: Self.self).lowercased()
  }

  var name: String {
    Self.name
  }

  static var defaultPackage: Self {
    try! {
      do {
        return try parse([])
      } catch {
        throw BuilderError.invalidDefaultPackage(name: String(describing: Self.self))
      }
    }()
  }

  var supportsBitcode: Bool { true }
  func supports(target: BuildTriple) -> Bool { true }

  func packageSource(for version: PackageVersion) -> PackageSource? { nil }

  var headSource: PackageSource? {
    packageSource(for: .head)
  }
}

extension Package {
  var identifier: ObjectIdentifier {
    .init(Self.self)
  }
}

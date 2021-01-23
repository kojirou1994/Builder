import ArgumentParser

public protocol Package: ParsableArguments, CustomStringConvertible {

  var dependencies: [Package] { get }
  var version: PackageVersion { get }
  var source: PackageSource { get }

  var buildInfo: String { get }

  func packageSource(for version: PackageVersion) -> PackageSource?
  func build(with builder: Builder) throws

}

public extension Package {

  var buildInfo: String { "" }

  var version: PackageVersion {
    // guess version from source
    fatalError("Unimplemented")
  }

  var description: String {
    """
    Name: \(name)
    Version: \(version)
    Source: \(source)
    Dependencies:
    \(dependencies.map(\.name).joined(separator: ", "))
    Information:
    \(buildInfo)
    """
  }

  var dependencies: [Package] {
    []
  }

  static var name: String {
    String(describing: Self.self).lowercased()
  }

  var name: String {
    Self.name
  }

  static func defaultPackage() -> Self {
    try! parse([])
  }

  func packageSource(for version: PackageVersion) -> PackageSource? { nil }
}

import ArgumentParser

protocol Package: ParsableArguments {
  func build(with builder: Builder) throws

  var dependencies: [Package] { get }
  var version: BuildVersion { get }
}

extension Package {

  var dependencies: [Package] {
    []
  }

  static var name: String {
    String(describing: Self.self).lowercased()
  }

  var name: String {
    Self.name
  }

  static func new() -> Self {
    try! parse([])
  }
}

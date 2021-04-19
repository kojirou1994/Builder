import Foundation

public struct EnvironmentValues {

  private(set) var values: [String : String]

  init() {
    values = ProcessInfo.processInfo.environment
  }

  public subscript(key: EnvironmentKey) -> String {
    get {
      values[key.string] ?? ""
    }
    set {
      values[key.string] = newValue.isEmpty ? nil : newValue
    }
  }

  public mutating func append(_ value: String, for key: EnvironmentKey, separator: String = " ") {
    guard !value.isEmpty else {
      return
    }
    var result = self[key]
    if !result.isEmpty {
      result.append(separator)
    }
    result.append(value)
    self[key] = result
  }

}

public struct EnvironmentKey {
  let string: String
}

extension EnvironmentKey: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.string = value
  }
}

public extension EnvironmentKey {
  static let cc: Self = "CC"
  static let cxx: Self = "CXX"
  static let path: Self = "PATH"
  static let pkgConfigPath: Self = "PKG_CONFIG_PATH"
  static let cflags: Self = "CFLAGS"
  static let cxxflags: Self = "CXXFLAGS"
  static let ldflags: Self = "LDFLAGS"
}

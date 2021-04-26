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
      values[key.string] = newValue
    }
    _modify {
      yield &values[key.string, default: ""]
    }
  }

  public mutating func append(_ value: String, for keys: EnvironmentKey..., separator: String = " ") {
    guard !value.isEmpty else {
      return
    }
    for key in keys {
      var result = self[key]
      if !result.isEmpty {
        result.append(separator)
      }
      result.append(value)
      self[key] = result
    }
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
  static let libs: Self = "LIBS"
  static let aclocalPath: Self = "ACLOCAL_PATH"
}

public enum EnvironmentValueSeparator {
  public static var path: String { ":" }
}

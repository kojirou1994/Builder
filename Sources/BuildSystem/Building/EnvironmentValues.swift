import Foundation

public struct EnvironmentValues {

  private(set) var values: [String : String]

  init() {
    self.values = ProcessInfo.processInfo.environment
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

  public mutating func append(_ value: String, toHead: Bool = false, for keys: EnvironmentKey...) {
    keys.forEach { key in
      let separator: String
      switch key {
      case .path, .pkgConfigPath, .aclocalPath:
        separator = EnvironmentValueSeparator.path
      case .cflags, .ldflags, .cxxflags,
           .libs:
        separator = EnvironmentValueSeparator.flag
      default: separator = ""
      }
      append(value, for: key, separator: separator)
    }
  }


  public mutating func append(_ value: String, toHead: Bool = false, for keys: EnvironmentKey..., separator: String) {
    guard !value.isEmpty else {
      return
    }
    for key in keys {
      if toHead {
        let oldValue = self[key]
        self[key] = value + (oldValue.isEmpty ? "" : separator) + oldValue
      } else {
        if !self[key].isEmpty {
          self[key].append(separator)
        }
        self[key].append(value)
      }
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
  static let cmakePrefixPath: Self = "CMAKE_PREFIX_PATH"
}

extension EnvironmentKey: Equatable { }

public enum EnvironmentValueSeparator {
  public static var path: String { ":" }
  public static var flag: String { " " }
}

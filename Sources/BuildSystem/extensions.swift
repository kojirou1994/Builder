public func configureEnableFlag(_ value: Bool, _ option: String) -> String {
  "--\(value ? "enable" : "disable")-\(option)"
}
public func configureEnableFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : configureEnableFlag(value, option)
}
public func configureEnableFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { configureEnableFlag(value, $0) }
}

public func configureWithFlag(_ value: Bool, _ package: String) -> String {
  "--with-\(package)=\(value ? "yes" : "no")"
}

public func cmakeOnFlag(_ value: Bool, _ option: String) -> String {
  "-D\(option)=\(value ? "ON" : "OFF")"
}
public func cmakeOnFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : cmakeOnFlag(value, option)
}
public func cmakeOnFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { cmakeOnFlag(value, $0) }
}

public func cmakeDefineFlag(_ value: String, _ option: String) -> String {
  "-D\(option)=\(value)"
}

public func mesonFeatureFlag(_ value: Bool, _ option: String) -> String {
  "-D\(option)=\(value ? "enabled" : "disabled")"
}

extension String {
  /// Returns a new string with the camel-case-based words of this string
  /// split by the specified separator.
  ///
  /// Examples:
  ///
  ///     "myProperty".convertedToSnakeCase()
  ///     // my_property
  ///     "myURLProperty".convertedToSnakeCase()
  ///     // my_url_property
  ///     "myURLProperty".convertedToSnakeCase(separator: "-")
  ///     // my-url-property
  func convertedToSnakeCase(separator: Character = "_") -> String {
    guard !isEmpty else { return self }
    var result = ""
    // Whether we should append a separator when we see a uppercase character.
    var separateOnUppercase = true
    for index in indices {
      let nextIndex = self.index(after: index)
      let character = self[index]
      if character.isUppercase {
        if separateOnUppercase && !result.isEmpty {
          // Append the separator.
          result += "\(separator)"
        }
        // If the next character is uppercase and the next-next character is lowercase, like "L" in "URLSession", we should separate words.
        separateOnUppercase = nextIndex < endIndex && self[nextIndex].isUppercase && self.index(after: nextIndex) < endIndex && self[self.index(after: nextIndex)].isLowercase
      } else {
        // If the character is `separator`, we do not want to append another separator when we see the next uppercase character.
        separateOnUppercase = character != separator
      }
      // Append the lowercased character.
      result += character.lowercased()
    }
    return result
  }
}

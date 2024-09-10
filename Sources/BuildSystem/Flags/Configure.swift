@inline(never)
public func configureEnableFlag(_ value: Bool, _ option: String) -> String {
  "--\(value ? "enable" : "disable")-\(option)"
}

@inline(never)
public func configureEnableFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : configureEnableFlag(value, option)
}

@inline(never)
public func configureEnableFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { configureEnableFlag(value, $0) }
}

@inline(never)
public func configureWithFlag(_ value: Bool, _ package: String) -> String {
  "--with-\(package)=\(value ? "yes" : "no")"
}

@inline(never)
public func configureWithFlag<T: CustomStringConvertible>(_ value: T?, _ package: String) -> String? {
  value.map { "--with-\(package)=\($0.description)" }
}

@inline(never)
public func cmakeOnFlag(_ value: Bool, _ option: String) -> String {
  "-D\(option)=\(value ? "ON" : "OFF")"
}

@inline(never)
public func cmakeOnFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : cmakeOnFlag(value, option)
}

@inline(never)
public func cmakeOnFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { cmakeOnFlag(value, $0) }
}

@inline(never)
public func cmakeDefineFlag<T: CustomStringConvertible>(_ value: T, _ option: String) -> String {
  "-D\(option)=\(value.description)"
}

@inline(never)
public func mesonFeatureFlag(_ value: Bool, _ option: String) -> String {
  "-D\(option)=\(value ? "enabled" : "disabled")"
}

@inline(never)
public func mesonDefineFlag<T: CustomStringConvertible>(_ value: T, _ option: String) -> String {
  "-D\(option)=\(value.description)"
}

import Foundation

public func replace(contentIn file: URL, matching string: String, with newString: String) throws {
  try String(contentsOf: file)
    .replacing(string, with: newString)
    .write(to: file, atomically: true, encoding: .utf8)
}

public func replace(contentIn file: String, matching string: String, with newString: String) throws {
  try replace(contentIn: URL(fileURLWithPath: file), matching: string, with: newString)
}

public func replace(contentIn file: URL, matching regex: some RegexComponent, with newString: String) throws {
  try String(contentsOf: file)
    .replacing(regex, with: newString)
    .write(to: file, atomically: true, encoding: .utf8)
}

public func replace(contentIn file: String, matching regex: some RegexComponent, with newString: String) throws {
  try replace(contentIn: URL(fileURLWithPath: file), matching: regex, with: newString)
}

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

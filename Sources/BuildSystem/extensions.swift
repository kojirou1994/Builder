extension Bool {
  public func configureFlag(_ option: String) -> String {
    "--\(self ? "enable" : "disable")-\(option)"
  }
  public func configureFlag(_ option: String, defaultEnabled: Bool) -> String? {
    self == defaultEnabled ? nil : configureFlag(option)
  }
  public func configureFlag(_ options: String...) -> [String] {
    options.map(configureFlag)
  }

  public func cmakeFlag(_ option: String) -> String {
    "-D\(option)=\(self ? "ON" : "OFF")"
  }
  public func cmakeFlag(_ option: String, defaultEnabled: Bool) -> String? {
    self == defaultEnabled ? nil : cmakeFlag(option)
  }
  public func cmakeFlag(_ options: String...) -> [String] {
    options.map(cmakeFlag)
  }
}

public func configureFlag(_ value: Bool, _ option: String) -> String {
  "--\(value ? "enable" : "disable")-\(option)"
}
public func configureFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : configureFlag(value, option)
}
public func configureFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { configureFlag(value, $0) }
}

public func cmakeFlag(_ value: Bool, _ option: String) -> String {
  "-D\(option)=\(value ? "ON" : "OFF")"
}
public func cmakeFlag(_ value: Bool, _ option: String, defaultEnabled: Bool) -> String? {
  value == defaultEnabled ? nil : cmakeFlag(value, option)
}
public func cmakeFlag(_ value: Bool, _ options: String...) -> [String] {
  options.map { cmakeFlag(value, $0) }
}

public func cmakeFlag(_ value: String, _ option: String) -> String {
  "-D\(option)=\(value)"
}

extension Bool {
  func configureFlag(_ option: String) -> String {
    "--\(self ? "enable" : "disable")-\(option)"
  }
  func configureFlag(_ option: String, defaultEnabled: Bool) -> String? {
    self == defaultEnabled ? nil : configureFlag(option)
  }
  func configureFlag(_ options: String...) -> [String] {
    options.map(configureFlag)
  }

  func cmakeFlag(_ option: String) -> String {
    "-D\(option)=\(self ? "ON" : "OFF")"
  }
  func cmakeFlag(_ option: String, defaultEnabled: Bool) -> String? {
    self == defaultEnabled ? nil : cmakeFlag(option)
  }
  func cmakeFlag(_ options: String...) -> [String] {
    options.map(cmakeFlag)
  }
}

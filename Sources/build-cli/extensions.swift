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
}

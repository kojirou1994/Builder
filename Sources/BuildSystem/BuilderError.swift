public enum BuilderError: Error {
  case missingBrewFormula([String])
  case installFailureBrewFormula([String])
  case invalidDefaultPackage(name: String)
}

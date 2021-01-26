public struct BrewInfo: Codable {
  public let formulae: [Formulae]
  public struct Formulae: Codable {
//    public let aliases: [String]
    public let bottleDisabled: Bool
    public let buildDependencies: [String]
    public let dependencies: [String]
    public let deprecated: Bool
    public let disabled: Bool
//    public let fullName: String
    public let installed: [Installed]
    public struct Installed: Codable {
      public let builtAsBottle: Bool
      public let installedAsDependency: Bool
      public let installedOnRequest: Bool
      public let pouredFromBottle: Bool
      public let runtimeDependencies: [RuntimeDependencies]
      public struct RuntimeDependencies: Codable {
        public let fullName: String
        public let version: String
        private enum CodingKeys: String, CodingKey {
          case fullName = "full_name"
          case version
        }
      }
      public let usedOptions: [String]
      public let version: String
      private enum CodingKeys: String, CodingKey {
        case builtAsBottle = "built_as_bottle"
        case installedAsDependency = "installed_as_dependency"
        case installedOnRequest = "installed_on_request"
        case pouredFromBottle = "poured_from_bottle"
        case runtimeDependencies = "runtime_dependencies"
        case usedOptions = "used_options"
        case version
      }
    }
    public let kegOnly: Bool
    public let license: String

    public let name: String
//    public let oldname: String
    public let optionalDependencies: [String]
    public let options: [String]
    public let outdated: Bool
    public let pinned: Bool
    public let recommendedDependencies: [String]
    public let requirements: [String]
    public let revision: Int

    public let usesFromMacos: [String]

    private enum CodingKeys: String, CodingKey {
//      case aliases

      case bottleDisabled = "bottle_disabled"
      case buildDependencies = "build_dependencies"
      case dependencies
      case deprecated
      case disabled
//      case fullName = "full_name"
      case installed
      case kegOnly = "keg_only"
      case license
      case name
//      case oldname
      case optionalDependencies = "optional_dependencies"
      case options
      case outdated
      case pinned
      case recommendedDependencies = "recommended_dependencies"
      case requirements
      case revision

      case usesFromMacos = "uses_from_macos"
    }
  }
  private enum CodingKeys: String, CodingKey {
    case formulae
  }
}

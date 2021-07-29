import BuildSystem
import ConsoleKit

private func showInfo(_ str: String) {
  print(str, terminator: "")
}

struct NewPackage: ParsableCommand {

  func run() throws {
    let console: Console = Terminal()
    let input = CommandInput(arguments: CommandLine.arguments)
    _ = CommandContext(console: console, input: input)

    var commands = Commands(enableAutocomplete: true)
    commands.use(_NewPackageCommand(), as: "new-package", isDefault: false)

    do {
      let group = commands
        .group(help: "")
      try console.run(group, input: input)
    } catch let error {
      console.error("\(error)")
      throw ExitCode(1)
    }
    
  }

}

private enum Toolchain: String, CustomStringConvertible, CaseIterable {

  case autotools
  case cmake
  case other

  var description: String { rawValue }

  var buildCode: String {
    switch self {
    case .other:
      return ""
    case .autotools:
      return """
          // try env.autoreconf()
          // try env.autogen()

          try env.configure(
            configureEnableFlag(false, CommonOptions.dependencyTracking),
            env.libraryType.staticConfigureFlag,
            env.libraryType.sharedConfigureFlag
          )

          try env.make()
          if env.strictMode {
            try env.make("check")
          }
          try env.make("install")
      """
    case .cmake:
      return """
          try env.inRandomDirectory { _ in
            try env.cmake(
              toolType: .ninja,
              ".."
            )

            try env.make(toolType: .ninja)
            try env.make(toolType: .ninja, "install")
          }
      """
    }
  }

  var depCode: String {
    switch self {
    case .other:
      return "[]"
    case .autotools:
      return """
      [
              .buildTool(Autoconf.self),
              .buildTool(Automake.self),
              .buildTool(Libtool.self),
            ]
      """
    case .cmake:
      return """
      [
              .buildTool(Cmake.self),
              .buildTool(Ninja.self),
            ]
      """
    }
  }
}

extension PackageVersion {
  var code: String {
    switch self {
    case .head:
      return ".head"
    case .stable(let version):
      return "\"\(version.toString())\""
    }
  }
}

private enum SourceType: String, CustomStringConvertible, CaseIterable {
  case repo
  case archive

  var description: String { rawValue }
}

private final class _NewPackageCommand: Command {
  var help: String { "" }

  struct Signature: CommandSignature {
    init() { }
  }

  func run(using context: CommandContext, signature: Signature) throws {

    let name = context.console.ask("What is your package's name?".consoleText(.info))
    context.console.print("Hello, \(name) 👋")
    let defaultVersionString = context.console.ask("What is your package's default version?".consoleText(.info))
    guard let defaultVersion = PackageVersion(defaultVersionString) else {
      throw ValidationError("Invalid version string: \(defaultVersionString), you should input standard semver or \"head\".")
    }
    let sourceType = context.console.choose("Choose your package's source type", from: SourceType.allCases)
    let sourceUrl = context.console.ask("What is your package's source url?".consoleText(.info))
    let toolchain = context.console.choose("Choose your package's build toolchain", from: Toolchain.allCases)
    var sourceCode = "."
    switch sourceType {
    case .archive:
      sourceCode.append("tarball")
    case .repo:
      sourceCode.append("repository")
    }
    sourceCode.append("(url: \"\(sourceUrl)\")")

    let packageStructName = name // convert latter
    let outputFileURL = URL(fileURLWithPath: packageStructName + ".swift")

    context.console.info("Wrting file to \(outputFileURL.path)")
    try """
    import BuildSystem

    public struct \(packageStructName): Package {

      public init() {}

      public var defaultVersion: PackageVersion {
        \(defaultVersion.code)
      }

      public func recipe(for order: PackageOrder) throws -> PackageRecipe {

        let source: PackageSource
        switch order.version {
        case .head:
          throw PackageRecipeError.unsupportedVersion
        case .stable(let version):
          let versionString = version.toString()
          source = \(sourceCode)
        }

        return .init(
          source: source,
          dependencies: \(toolchain.depCode)
        )
      }

      public func build(with context: BuildContext) throws {
    \(toolchain.buildCode)
      }
    }
    """
      .write(to: outputFileURL, atomically: true, encoding: .utf8)
  }
}

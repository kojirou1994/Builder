import BuildSystem

public struct Choco: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "git@github.com:kojirou1994/Choco.git", requirement: .branch("main"))
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(x265 { p in
          p.enable10bit = false
          p.enable12bit = false
        }),
        .runTime(Bluray { p in
          p.freetype = false
        }),
      ],
      products: [
        .bin("choco-cli"),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    let flags = try env.launchResult("pkg-config", ["--libs", "--static", "x265", "libbluray"])
      .utf8Output()
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: " ")

    var arguments = ["build", "-c", "release"] as [String?]
    if env.libraryType == .static {
      flags.forEach { flag in
        if flag.hasPrefix("-R") {
          print("invalid libs: \(flag)")
        } else {
          arguments.append(contentsOf: ["-Xlinker", String(flag)])
        }
      }
    }
    try env.launch("swift", arguments)
    try env.mkdir(env.prefix.bin)
    try env.copyItem(at: URL(fileURLWithPath: ".build/release/choco-cli"), toDirectory: env.prefix.bin)
  }

}

import BuildSystem

public struct DlbMp4base: Package {

  public static var name: String { "dlb_mp4base" }

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS, .linuxGNU, .macCatalyst:
      break
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/DolbyLaboratories/dlb_mp4base.git")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    context.environment["EXTRA_LDFLAGS"] = context.environment[.ldflags]
    context.environment["EXTRA_CFLAGS"] = context.environment[.cflags]

    try context.changingDirectory("make/libmp4base/linux_amd64") { _ in
      let target = "libmp4base_release.a"
      try context.make(target)

      let product = URL(fileURLWithPath: "libmp4base.a")
      try context.moveItem(at: URL(fileURLWithPath: target), to: product)

      try context.install(product, toDirectory: context.prefix.lib)
    }

    try context.changingDirectory("make/mp4muxer/linux_amd64") { _ in
      let target = "mp4muxer_release"
      try context.make(target)

      let product = URL(fileURLWithPath: "mp4muxer")
      try context.moveItem(at: URL(fileURLWithPath: target), to: product)

      try context.install(product, toDirectory: context.prefix.bin)
    }

    try context.copyItem(at: URL(fileURLWithPath: "include"), to: context.prefix.include)

  }
}

import BuildSystem

public struct Flash3kyuuDeband: Package {
  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/SAPikachu/flash3kyuu_deband/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/SAPikachu/flash3kyuu_deband/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .pip(["meson"]),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch(path: "./waf", "configure", "--prefix=\(context.prefix.root.path)")
    try context.launch(path: "./waf", "build")
//    try context.launch(path: "./waf", "install")
    let filename = "build/libf3kdb.\(context.order.target.system.sharedLibraryExtension)"

    let installDir = context.prefix.lib.appendingPathComponent("vapoursynth")
    try context.mkdir(installDir)

    try context.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
  }
}

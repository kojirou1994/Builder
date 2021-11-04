import BuildSystem

public struct Znedi3: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource = .repository(url: "https://github.com/sekrit-twc/znedi3.git", requirement: .revision("4090c5c3899be7560380e0420122ac9097ef9e8e"))
//    switch order.version {
//    case .head:
//      source = .repository(url: "https://github.com/sekrit-twc/znedi3.git")
//    case .stable(let version):
//      source = .tarball(url: "https://github.com/sekrit-twc/znedi3/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
//    }

    return .init(
      source: source,
      dependencies:[
        .runTime(Vapoursynth.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.make(
      "x86=\(context.order.target.arch.isX86 ? 1: 0)"
    )

    try context.mkdir(context.prefix.lib)

    let pluginURL = context.prefix.lib.appendingPathComponent("vsznedi3.\(context.order.target.system.sharedLibraryExtension)")
    try context.copyItem(at: URL(fileURLWithPath: "vsznedi3.so"), to: pluginURL)

    try Vapoursynth.install(plugin: context.prefix.lib.appendingPathComponent("vsznedi3"), context: context)

  }
}

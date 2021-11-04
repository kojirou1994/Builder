import BuildSystem

public struct Mvtools: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/kojirou1994/vapoursynth-mvtools.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/kojirou1994/vapoursynth-mvtools/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        order.target.arch.isX86 ? .buildTool(Nasm.self) : nil,
        .runTime(Vapoursynth.self),
        .runTime(Fftw.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {

    if context.order.target.arch.isARM {
      let old = "nasm_flags += ['-DPREFIX', '-f', 'macho@0@'.format(host_x86_bits)]"
      try replace(contentIn: "meson.build", matching: old, with: "")
    }

    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")

      try Vapoursynth.install(plugin: context.prefix.appending("lib", "libmvtools"), context: context)
    }
  }
}

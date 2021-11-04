import BuildSystem

private let lastAutoToolsVersion: PackageVersion = "1.1.1"

public struct KNLMeansCL: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    var deps: [PackageDependency]
    if order.version > lastAutoToolsVersion {
      deps = [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .runTime(Boost.self),
      ]
    } else {
      deps = []
    }
    deps.append(.runTime(Vapoursynth.self))
    deps.append(.buildTool(PkgConfig.self))
    return .init(
      source: source,
      dependencies: deps
    )
  }

  public func build(with context: BuildContext) throws {
    if context.order.version > lastAutoToolsVersion {
      /*
       thanks to:
       https://unix.stackexchange.com/questions/408963/meson-doesnt-find-the-boost-libraries
       */
      try replace(contentIn: "meson.build", matching: "boost_dep = dependency('boost', modules : ['filesystem', 'system'])", with: """
        cxx = meson.get_compiler('cpp')
        boost_dep = [
          cxx.find_library('boost_system'),
          cxx.find_library('boost_filesystem'),
        ]
        """)
      try context.inRandomDirectory { _ in
        try context.meson("..")

        try context.make(toolType: .ninja)
        try context.make(toolType: .ninja, "install")
      }
    } else {
      try replace(contentIn: "GNUmakefile", matching: "$(STRIP) $(LIBNAME)", with: "")
      try context.launch(
        path: "./configure",
        "--install=\(context.prefix.lib.appendingPathComponent("vapoursynth").path)",
        "--cxx=\(context.cxx)"
        )

      try context.make()
      try context.make("install")
    }

    try Vapoursynth.install(plugin: context.prefix.appending("lib", "vapoursynth", "libknlmeanscl"), context: context)
  }
}

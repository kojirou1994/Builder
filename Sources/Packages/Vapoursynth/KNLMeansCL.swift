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
        .pip(["meson"]),
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

  public func build(with env: BuildEnvironment) throws {
    if env.order.version > lastAutoToolsVersion {
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
      try env.changingDirectory(env.randomFilename) { _ in
        try env.meson("..")

        try env.launch("ninja")
        try env.launch("ninja", "install")
      }
    } else {
      try replace(contentIn: "GNUmakefile", matching: "$(STRIP) $(LIBNAME)", with: "")
      try env.launch(
        path: "./configure",
        "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)",
        "--cxx=\(env.cxx)"
        )

      try env.make()
      try env.make("install")
    }

  }
}

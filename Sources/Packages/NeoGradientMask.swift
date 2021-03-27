import BuildSystem

struct NeoGradientMask: Package {

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_Gradient_Mask/archive/refs/heads/master.zip")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
//      let filename = "libneo-fft3d.\(env.target.system.sharedLibraryExtension)"
//
//      let installDir = env.prefix.lib.appendingPathComponent("vapoursynth")
//      try env.fm.createDirectory(at: installDir)
//
//      try env.fm.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
    })
  }
}

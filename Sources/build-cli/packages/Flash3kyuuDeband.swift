import BuildSystem

struct Flash3kyuuDeband: Package {

//  var defaultVersion: PackageVersion {
//    .stable("2.0.0")
//  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/SAPikachu/flash3kyuu_deband/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/SAPikachu/flash3kyuu_deband/archive/refs/tags/\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "./waf", "configure", "--prefix=\(env.prefix.root.path)")
    try env.launch(path: "./waf", "build")
//    try env.launch(path: "./waf", "install")
    let filename = "build/libf3kdb.\(env.target.system.sharedLibraryExtension)"

    let installDir = env.prefix.lib.appendingPathComponent("vapoursynth")
    try env.fm.createDirectory(at: installDir)

    try env.fm.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
  }
}

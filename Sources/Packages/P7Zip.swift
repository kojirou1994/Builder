import BuildSystem

public struct P7Zip: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "17.4.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/jinfeihan57/p7zip/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/jinfeihan57/p7zip/archive/refs/tags/v\(version.toString( includeZeroPatch: false, numberWidth: 2)).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {

    try context.removeItem(at: URL(fileURLWithPath: "makefile.machine"))
    try context.copyItem(at: URL(fileURLWithPath: "makefile.macosx_llvm_64bits"), to: URL(fileURLWithPath: "makefile.machine"))
    try context.make("all3")
    try context.launch("make", "DEST_HOME=\(context.prefix.root.path)", "install")
    /*
     cmake no install target
     https://github.com/jinfeihan57/p7zip/issues/116
     */
//    try context.changingDirectory("CPP/7zip/CMAKE/build") { _ in
//      try context.cmake(toolType: .ninja, "..")
//
//      try context.make(toolType: .ninja)
//      try context.make(toolType: .ninja, "install")
//    })

  }
}

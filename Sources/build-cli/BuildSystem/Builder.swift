import URLFileManager
import KwiftUtility

struct Builder {

  var builtPackages: Set<String> = .init()

  private let launcher = BuilderLauncher()

  let fm = URLFileManager.default

  let settings: BuildSettings

  let srcRootDirectoryURL: URL

  let productsDirectoryURL: URL

  let downloadCacheDirectory: URL

  func launch<T>(_ executable: T) throws where T : Executable {
    _ = try launcher.launch(executable: executable, options: .init(checkNonZeroExitCode: true))
  }

  func launch(_ executableName: String, _ arguments: String?...) throws {
    try launch(executableName, arguments)
  }
  func launch(_ executableName: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}))
  }
  func launch(path: String, _ arguments: String?...) throws {
    try launch(path: path, arguments)
  }

  func launch(path: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}))
  }

  func withChangingDirectory(_ path: String, create: Bool = true, block: (URL) throws -> ()) throws {
    try withChangingDirectory(URL(fileURLWithPath: path), create: create, block: block)
  }

  func withChangingDirectory(_ url: URL, create: Bool = true, block: (URL) throws -> ()) throws {
    if create {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    let oldDir = FileManager.default.currentDirectoryPath
    FileManager.default.changeCurrentDirectoryPath(url.path)
    print("Current in:", url.path)
    defer {
      FileManager.default.changeCurrentDirectoryPath(oldDir)
      print("Back to:", oldDir)
    }
    try block(url)
  }

  func checkout(version: BuildVersion, directory: String) throws {
    switch version {
    case .branch(repo: let repo, revision: _):
      try launch("git", "clone", repo, directory)
    case .ball(url: let url, filename: let filename):
      let filename = filename ?? url.lastPathComponent
      let dstFileURL = downloadCacheDirectory.appendingPathComponent(filename)
      if !URLFileManager.default.fileExistance(at: dstFileURL).exists {
        let tmpFileURL = dstFileURL.appendingPathExtension("tmp")
        if fm.fileExistance(at: tmpFileURL).exists {
          try removeItem(at: tmpFileURL)
        }
        try launch("wget", "-O", tmpFileURL.path, url.absoluteString)
        try URLFileManager.default.moveItem(at: tmpFileURL, to: dstFileURL)
      }

      try launch("tar", "xf", dstFileURL.path)

      let uncompressedURL = URL(fileURLWithPath: dstFileURL.deletingPathExtension().deletingPathExtension().lastPathComponent)
      try URLFileManager.default.moveItem(at: uncompressedURL, to: URL(fileURLWithPath: directory))
    }
  }

  func removeItem(at url: URL) throws {
    try retry(body: try fm.removeItem(at: url))
  }

  func mkdir(_ path: String) throws {
    try mkdir(URL(fileURLWithPath: path))
  }

  func mkdir(_ url: URL) throws {
    try fm.createDirectory(at: url)
  }
}

extension Builder {
  func build(package: Package) throws {
    if builtPackages.contains(package.name) {
      print("SKIP BUILDING \(package.name).")
      return
    }
    try withChangingDirectory(srcRootDirectoryURL, block: { cwd in
      let srcDir = cwd.appendingPathComponent(package.name)
      if fm.fileExistance(at: srcDir).exists {
        try removeItem(at: srcDir)
      }

      try checkout(
        version: package.version,
        directory: srcDir.lastPathComponent)

      try withChangingDirectory(srcDir, block: { _ in
        try package.build(with: self)
      })
    })
  }
}

// MARK: Common tools
extension Builder {
  func make(_ targets: String...) throws {
    try launch(Make(targets: targets))
  }

  func cmake(_ arguments: String?...) throws {
    try cmake(arguments)
  }
  func cmake(_ arguments: [String?]) throws {
    try launch("cmake",
               ["-DCMAKE_INSTALL_PREFIX=\(settings.prefix)", "-DCMAKE_BUILD_TYPE=Release"]
                + arguments.compactMap {$0})
  }

  func meson(_ arguments: String?...) throws {
    try meson(arguments)
  }
  func meson(_ arguments: [String?]) throws {
    try launch("meson",
               ["--prefix=\(settings.prefix)",
                "--buildtype=release",
//                "--wrap-mode=nofallback
               ]
                + arguments.compactMap {$0})
  }

  func configure(_ arguments: String?...) throws {
    try configure(arguments)
  }

  func configure(_ arguments: [String?]) throws {
    try launch(path: "configure",
               CollectionOfOne("--prefix=\(settings.prefix)") + arguments.compactMap {$0})
  }

  func autoreconf() throws {
    try launch("autoreconf", "-if")
  }
}

func replace(contentIn file: URL, matching string: String, with newString: String) throws {
  try String(contentsOf: file)
    .replacingOccurrences(of: string, with: newString)
    .write(to: file, atomically: true, encoding: .utf8)
}

func replace(contentIn file: String, matching string: String, with newString: String) throws {
  try replace(contentIn: URL(fileURLWithPath: file), matching: string, with: newString)
}

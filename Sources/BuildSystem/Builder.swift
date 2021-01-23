import URLFileManager
import KwiftUtility

public struct Builder {

  var builtPackages: Set<String> = .init()

  private let launcher = BuilderLauncher()

  public let fm = URLFileManager.default

  public let settings: BuildSettings

  let srcRootDirectoryURL: URL

  public let productsDirectoryURL: URL

  let downloadCacheDirectory: URL

  public func launch<T>(_ executable: T) throws where T : Executable {
    _ = try launcher.launch(executable: executable, options: .init(checkNonZeroExitCode: true))
  }

  public func launch(_ executableName: String, _ arguments: String?...) throws {
    try launch(executableName, arguments)
  }
  public func launch(_ executableName: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}))
  }
  public func launch(path: String, _ arguments: String?...) throws {
    try launch(path: path, arguments)
  }

  public func launch(path: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}))
  }

  public func changingDirectory(_ path: String, create: Bool = true, block: (URL) throws -> ()) throws {
    try changingDirectory(URL(fileURLWithPath: path), create: create, block: block)
  }

  public func changingDirectory(_ url: URL, create: Bool = true, block: (URL) throws -> ()) throws {
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

  func checkout(source: PackageSource, directory: String) throws {
    switch source.requirement {
    case .revisionItem(let revision):
      try launch("git", "clone", source.url, directory)
    case .tarball(filename: let filename):
      let url = URL(string: source.url)!
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
    default: fatalError()
    }
  }

  public func removeItem(at url: URL) throws {
    try retry(body: try fm.removeItem(at: url))
  }

  public func mkdir(_ path: String) throws {
    try mkdir(URL(fileURLWithPath: path))
  }

  public func mkdir(_ url: URL) throws {
    try fm.createDirectory(at: url)
  }
}

extension Builder {
  func build(package: Package, version: String? = nil) throws {
    if builtPackages.contains(package.name) {
      print("SKIP BUILDING \(package.name).")
      return
    }
    try changingDirectory(srcRootDirectoryURL, block: { cwd in
      let srcDir = cwd.appendingPathComponent(package.name)
      if fm.fileExistance(at: srcDir).exists {
        try removeItem(at: srcDir)
      }

      let source: PackageSource
      if let v = version {
        if let s = package.packageSource(for: .stable(v)) {
          print("Using custom version: \(v), source: \(s)")
          source = s
        } else {
          print("Invalid custom version: \(v), use default source!")
          source = package.source
        }
      } else {
        source = package.source
      }
      try checkout(
        source: source,
        directory: srcDir.lastPathComponent)

      try changingDirectory(srcDir, block: { _ in
        try package.build(with: self)
      })
    })
  }
}

// MARK: Common tools
extension Builder {
  public func make(_ targets: String...) throws {
    try launch(Make(jobs: settings.parallelJobs, targets: targets))
  }

  public func rake(_ targets: String...) throws {
    try launch(Rake(jobs: settings.parallelJobs, targets: targets))
  }

  public func cmake(_ arguments: String?...) throws {
    try cmake(arguments)
  }
  public func cmake(_ arguments: [String?]) throws {
    try launch("cmake",
               ["-DCMAKE_INSTALL_PREFIX=\(settings.prefix)", "-DCMAKE_BUILD_TYPE=Release"]
                + arguments.compactMap {$0})
  }

  public func meson(_ arguments: String?...) throws {
    try meson(arguments)
  }
  public func meson(_ arguments: [String?]) throws {
    try launch("meson",
               ["--prefix=\(settings.prefix)",
                "--buildtype=release",
//                "--wrap-mode=nofallback
               ]
                + arguments.compactMap {$0})
  }

  public func configure(_ arguments: String?...) throws {
    try configure(arguments)
  }

  public func configure(_ arguments: [String?]) throws {
    try launch(path: "configure",
               CollectionOfOne("--prefix=\(settings.prefix)") + arguments.compactMap {$0})
  }

  public func autoreconf() throws {
    try launch("autoreconf", "-if")
  }
}

public func replace(contentIn file: URL, matching string: String, with newString: String) throws {
  try String(contentsOf: file)
    .replacingOccurrences(of: string, with: newString)
    .write(to: file, atomically: true, encoding: .utf8)
}

public func replace(contentIn file: String, matching string: String, with newString: String) throws {
  try replace(contentIn: URL(fileURLWithPath: file), matching: string, with: newString)
}

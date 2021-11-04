import URLFileManager

public struct PackageBuildCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  @Flag()
  var info: Bool = false

  @Option()
  var arch: TargetArch = .native

  @Option()
  var system: TargetSystem = .native

  @Option(help: "Set target system version.")
  var deployTarget: String?

  @OptionGroup
  var builderOptions: BuilderOptions

  @OptionGroup
  var installOptions: InstallOptions

  @OptionGroup
  var package: T

  @Flag(inversion: .prefixedEnableDisable, help: "Add library target/type info in prefix")
  var prefixLibInfo: Bool = true

  var target: TargetTriple {
    .init(arch: arch, system: system)
  }

  public mutating func run() throws {
    dump(builderOptions.packageVersion)
    if info {
      print(package)
    } else {
      let builder = try Builder(options: builderOptions, target: target,
                                addLibInfoInPrefix: prefixLibInfo, deployTarget: deployTarget)

      let buildResult = try builder.startBuild(package: package, version: builderOptions.packageVersion, libraryType: builderOptions.library)
      builder.logger.info("Package is installed at: \(buildResult.prefix.root.path)")

      if let installContent = installOptions.installContent {
        let fm: URLFileManager = .init()

        let installDestPrefix = URL(fileURLWithPath: installOptions.installPrefix)

        func install(from prefix: PackagePath) throws {
          let action = installOptions.uninstall ? "Uninstalling" : "Installing"
          builder.logger.info("\(action) from \(prefix)")
          let installSources: [URL]
          switch installContent {
          case .bin:
            installSources = [prefix.bin]
          case .lib:
            installSources = [prefix.include, prefix.lib]
          case .all:
            installSources = [prefix.root]
          case .pkgconfig:
            installSources = [prefix.pkgConfig]
          }

          installSources.forEach { installSource in
            guard let enumerator = fm.enumerator(at: installSource, options: [.skipsHiddenFiles]) else {
              // show error
              return
            }
            for case let url as URL in enumerator {
              if fm.fileExistance(at: url) == .file {
                let relativePath = url.path.dropFirst(prefix.root.path.count)
                  .drop(while: {"/" == $0 })

                let destURL = installDestPrefix.appendingPathComponent(String(relativePath))

                if installOptions.uninstall {
                  do {
                    if fm.fileExistance(at: destURL).exists {
                      print("removing \(destURL.path)")
                      try fm.removeItem(at: destURL)
                    }
                  } catch {
                    print("uninstall failed: \(error.localizedDescription)")
                  }
                } else {
                  print("\(relativePath) --> \(destURL.path)")
                  try! fm.createDirectory(at: destURL.deletingLastPathComponent())
                  do {
                    if fm.isDeletableFile(at: destURL), installOptions.forceInstall {
                      print("removing existed \(destURL.path)")
                      try fm.removeItem(at: destURL)
                    }
                    switch installOptions.installMethod {
                    case .link:
                      try fm.createSymbolicLink(at: destURL, withDestinationURL: url)
                    case .copy:
                      try fm.copyItem(at: url, to: destURL)
                    }
                  } catch {
                    print("install failed: \(error.localizedDescription)")
                  }
                }
              }
            }
          } // installSources forEach end
        } // install func end

        try install(from: buildResult.prefix)
        switch installOptions.installLevel {
        case .package:
          break
        case .runTime:
          try buildResult.runTimeDependencyMap.allPackagePrefixes.forEach { prefix in
            try install(from: prefix)
          }
        case .all:
          try buildResult.dependencyMap.allPackagePrefixes.forEach { prefix in
            try install(from: prefix)
          }
        }
      }
    }
  }
}

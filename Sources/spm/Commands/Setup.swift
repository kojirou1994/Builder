import Foundation
import URLFileManager
import ArgumentParser
import KwiftExtension
import Logging
import BuildSystem
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#else
#error("Unsupported platform!")
#endif
import PrettyBytes

func checkValidSPM(logger: Logger) throws {
  guard fm.fileExistance(at: URL(fileURLWithPath: "Package.swift")).exists else {
    logger.error("No swift package manifest file!")
    throw ExitCode(1)
  }
}

func getBuildPath(logger: Logger, archs: [TargetArch], prefix: String, rootPath: String?) throws -> URL {
  guard let rootPath = (rootPath ?? ProcessInfo.processInfo.environment[EnvKeys.spmBuild]),
        !rootPath.isEmpty else {
    logger.error("No environment value or option for \(EnvKeys.spmBuild)!")
    throw ExitCode(2)
  }

  let name = fm.currentDirectory.lastPathComponent
  let hash = BytesStringFormatter(uppercase: false)
    .bytesToHexString(SHA256.hash(data: Array(fm.currentDirectory.absoluteString.utf8)).prefix(14))
  let suffix = archs.map { "_" + $0.clangTripleString }.joined()
  return URL(fileURLWithPath: rootPath)
    .appendingPathComponent("\(name)-\(hash)")
    .appendingPathComponent(prefix + suffix)
}

struct Setup: ParsableCommand {
  @Flag(name: .long, help: "remove existed dir and then create new dir")
  var force: Bool = false

  @Option
  var path: String?

  func run() throws {

    let logger = Logger(label: "setup")

    try checkValidSPM(logger: logger)

    let destBuildURL = try getBuildPath(logger: logger, archs: [], prefix: "build", rootPath: path)
    logger.info("Desired path is \(destBuildURL.path)")

    let buildURL = fm.currentDirectory.appendingPathComponent(".build")

    func removeOld() throws {
      logger.info("Removing existing .build link")
      try fm.removeItem(at: buildURL)
    }

    if let attributes = try? fm.attributesOfItem(atURL: buildURL) {
      if (attributes[.type] as! FileAttributeType) == .typeSymbolicLink {
        let oldDesti = URL(fileURLWithPath: try fm.destinationOfSymbolicLink(at: buildURL))
        if fm.fileExistance(at: oldDesti).exists {
          if force {
            try fm.removeItem(at: oldDesti)
            try removeOld()
          } else {
            logger.warning("The build path is alredy set to \(oldDesti.path)")
            return
          }
        } else {
          logger.info("The build path is invalid, creating a new one.")
          try removeOld()
        }
      } else {
        try removeOld()
      }
    }

    try fm.createDirectory(at: destBuildURL)

    try fm.createSymbolicLink(at: buildURL, withDestinationURL: destBuildURL)

    logger.info("build path is now set to \(destBuildURL.path)")
  }
}

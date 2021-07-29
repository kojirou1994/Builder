import Foundation
import URLFileManager
import ArgumentParser
import KwiftExtension

fileprivate let SPM_BUILD_PATH = "SPM_BUILD_PATH"

struct Setup: ParsableCommand {
  @Flag(name: .long, help: "remove existed dir and then create new dir")
  var force: Bool = false

  func run() throws {
    try spmSetup(force: force)
  }
}

func spmSetup(force: Bool) throws {
  guard fm.fileExistance(at: URL(fileURLWithPath: "Package.swift")).exists else {
    print("No swift package manifest file!")
    throw ExitCode(1)
  }

  let buildRootURL = try URL(fileURLWithPath: (ProcessInfo.processInfo.environment[SPM_BUILD_PATH].unwrap("No environment value or option for \(SPM_BUILD_PATH)")))

  let buildURL = fm.currentDirectory.appendingPathComponent(".build")

  func removeOld() throws {
    print("Removing existing .build directory")
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
          print("The build path is alredy set to \(oldDesti.path)")
          return
        }
      } else {
        print("The build path is invalid, creating a new one.")
        try removeOld()
      }
    } else {
      try removeOld()
    }
  }

  let directoryName = fm.currentDirectory.lastPathComponent + "_" + UUID().uuidString

  let destBuildURL = buildRootURL.appendingPathComponent(directoryName)

  try fm.createDirectory(at: destBuildURL)

  try fm.createSymbolicLink(at: buildURL, withDestinationURL: destBuildURL)

  print("build path is now set to \(destBuildURL.path)")
}

import Foundation

public struct PackagePath {
  public let root: URL

  public var bin: URL {
    root.appendingPathComponent("bin")
  }

  public var include: URL {
    root.appendingPathComponent("include")
  }

  public var lib: URL {
    root.appendingPathComponent("lib")
  }

  public var pkgConfig: URL {
    appending("lib", "pkgconfig")
  }

  public func appending(_ pathComponents: String...) -> URL {
    guard !pathComponents.isEmpty else {
      return root
    }
    var result = root
    pathComponents.forEach { result.appendPathComponent($0) }
    return result
  }
}

import Foundation

public struct PackagePath: Hashable, CustomStringConvertible {
  public init(_ root: URL) {
    self.root = root
  }

  public let root: URL

  public var bin: URL {
    root.appendingPathComponent("bin")
  }

  public var include: URL {
    root.appendingPathComponent("include")
  }

  public var cflag: String {
    "-I\(include.path)"
  }

  public var ldflag: String {
    "-L\(lib.path)"
  }

  public var lib: URL {
    root.appendingPathComponent("lib")
  }

  public var share: URL {
    root.appendingPathComponent("share")
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

  public var description: String {
    root.path
  }
}

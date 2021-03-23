import Foundation

public struct PackagePatch {

}

public struct PackageSource: CustomStringConvertible {
  public let url: String
  let requirement: Requirement
  enum Requirement {
    // url is git repo
    case exactItem(String)
    //  case rangeItem(Range<Version>)
    case revisionItem(String?)
    case branchItem(String)
    //    case localPackageItem

    // url is download link
    case tarball(filename: String?, sha256: String?)

    var isGitRepo: Bool {
      switch self {
      case .tarball:
        return false
      default:
        return true
      }
    }
  }
  public var patches: [PackagePatch]

  public static func branch(repo: String, revision: String? = nil,
                            patches: [PackagePatch] = []) -> Self {
    .init(url: repo, requirement: .revisionItem(revision), patches: patches)
  }

  public static func tarball(url: String, filename: String? = nil,
                             sha256: String? = nil,
                             patches: [PackagePatch] = []) -> Self {
    .init(url: url, requirement: .tarball(filename: filename, sha256: sha256), patches: patches)
  }

  public var description: String {
    //    switch requirement {
    //    case .branch(repo: let repo, revision: _):
    //      return "[GIT REPO] \(repo)"
    //    case .ball(url: let url, filename: _):
    //      return "[BALL URL] \(url)"
    //    }
    "url: \(url), requirement: \(requirement)"
  }
}

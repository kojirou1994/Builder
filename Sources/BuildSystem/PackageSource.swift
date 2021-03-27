import Foundation

public struct PackagePatch {

}

public struct PackageSource: CustomStringConvertible {
  public let url: String
  let requirement: Requirement
  enum Requirement {
    // url is git repo
    case repository(RepositoryRequirement)


    // url is download link
    case tarball(sha256: String?)

    var isGitRepo: Bool {
      switch self {
      case .tarball:
        return false
      default:
        return true
      }
    }
  }

  public enum RepositoryRequirement {
    case tag(String)
    case revision(String)
    case branch(String)
  }
  public var patches: [PackagePatch]

  public static func repository(url: String, requirement: RepositoryRequirement,
                                patches: [PackagePatch] = []) -> Self {
    .init(url: url, requirement: .repository(requirement), patches: patches)
  }

  public static func tarball(url: String,
                             sha256: String? = nil,
                             patches: [PackagePatch] = []) -> Self {
    .init(url: url, requirement: .tarball(sha256: sha256), patches: patches)
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

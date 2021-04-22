import Foundation

public struct PackagePatch {
  public init(url: String, sha256: String) {
    self.url = url
    self.sha256 = sha256
  }

  public let url: String
  public let sha256: String
}

public struct PackageSource: CustomStringConvertible {
  public let url: String
  let requirement: Requirement
  let mirrors: [String]

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
                                patches: [PackagePatch] = [],
                                mirrors: [String] = []) -> Self {
    .init(url: url, requirement: .repository(requirement), patches: patches, mirrors: mirrors)
  }

  public static func tarball(url: String,
                             sha256: String? = nil,
                             patches: [PackagePatch] = [],
                             mirrors: [String] = []) -> Self {
    .init(url: url, requirement: .tarball(sha256: sha256), patches: patches, mirrors: mirrors)
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

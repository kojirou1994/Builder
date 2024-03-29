import Foundation

public enum PackagePatch {
  case remote(url: String, sha256: String?, tool: PatchTool)
  case raw(String)

  public static func remote(url: String, sha256: String?) -> Self {
    .remote(url: url, sha256: sha256, tool: .git)
  }

  public enum PatchTool {
    case git
    case patch(stripCount: Int)
  }
}

public struct PackageSource: CustomStringConvertible {
  public let url: String
  let requirement: Requirement
  public var patches: [PackagePatch]
  let mirrors: [String]

  enum Requirement {
    // url is git repo
    case repository(RepositoryRequirement?, RepositorySubmodule)

    // url is download link
    case tarball(sha256: String?)
    case empty

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

  public enum RepositorySubmodule {
    case all
    case none
    case paths([String])
  }

  public static func repository(url: String, requirement: RepositoryRequirement? = nil,
                                submodule: RepositorySubmodule = .all,
                                patches: [PackagePatch] = [],
                                mirrors: [String] = []) -> Self {
    .init(url: url, requirement: .repository(requirement, submodule), patches: patches, mirrors: mirrors)
  }

  public static func tarball(url: String,
                             sha256: String? = nil,
                             patches: [PackagePatch] = [],
                             mirrors: [String] = []) -> Self {
    .init(url: url, requirement: .tarball(sha256: sha256), patches: patches, mirrors: mirrors)
  }

  public static var empty: Self {
    .init(url: "", requirement: .empty, patches: [], mirrors: [])
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

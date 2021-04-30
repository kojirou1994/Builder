//import TSCBasic
//import TSCUtility
import ExecutableLauncher
import URLFileManager
import KwiftUtility
import XcodeExecutable
import Logging
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Version {
  var testGroup: [Version] {
    [nextPatch,
     nextMinor, nextMinor.nextPatch,
     nextMajor, nextMajor.nextPatch, nextMajor.nextMinor.nextPatch]
  }
}

extension Version: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

import BuildSystem

private func showInfo(_ str: String) {
  print(str, terminator: "")
}

struct NewPackage: ParsableCommand {

  func run() throws {
    showInfo("Input the package tarball url:")
    if let url = readLine() {
      print("URL: \(url)")
    }
  }

}

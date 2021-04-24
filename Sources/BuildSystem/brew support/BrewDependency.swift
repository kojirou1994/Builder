import Foundation
import ExecutableLauncher
import KwiftExtension

extension Builder {
  func parseBrewDeps(_ formulas: [String], installIfMissing: Bool = true, requireLinked: Bool)
  throws -> [String : PackagePath] {
    guard !formulas.isEmpty else {
      return .init()
    }

    let missingFormulas = try brewInfo(formulas)
      .formulae.filter { $0.installed.isEmpty }
      .map(\.name)

    if !missingFormulas.isEmpty {
      if installIfMissing {
        try AnyExecutable(executableName: "brew", arguments: ["install"] + missingFormulas)
          .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
      } else {
        throw BuilderError.missingBrewFormula(missingFormulas)
      }
    }

    let checkMissingFormulas = try brewInfo(formulas)
      .formulae.filter { $0.installed.isEmpty }
    precondition(checkMissingFormulas.isEmpty, "some formula is still not installed! \(checkMissingFormulas)")

    var allUsedBrewPackages = Set<String>()

    var currentFindFormulas = formulas

    while !currentFindFormulas.isEmpty {
      let info = try brewInfo(currentFindFormulas)

      var formulaDependencies = [String]()

      info.formulae.forEach { formulaInfo in
//        depMap[formulaInfo.name] = .init(root: URL(fileURLWithPath: formulaInfo.))
        allUsedBrewPackages.insert(formulaInfo.name)
        formulaDependencies.append(contentsOf: formulaInfo.dependencies)
      }

      currentFindFormulas = formulaDependencies
    }

    if requireLinked {
      try AnyExecutable(executableName: "brew", arguments: ["link"] + formulas)
        .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
      return .init()
    }

    var depMap = [String : PackagePath]()
    try allUsedBrewPackages.forEach { formula in
      let prefix = try AnyExecutable(executableName: "brew", arguments: ["--prefix", formula])
        .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
        .utf8Output().trimmingCharacters(in: .whitespacesAndNewlines)
      depMap[formula] = .init(root: URL(fileURLWithPath: prefix))
    }

    return depMap
  }

  func brewInfo(_ formulas: [String]) throws -> BrewInfo {
    let decoder = JSONDecoder()
    let output = try AnyExecutable(executableName: "brew",
                                   arguments: ["info", "--json=v2"] + formulas)
      .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
      .output.get()
    #warning("check error")
    // Error: No available formula or cask with the name "gcc22".
    return try decoder.kwiftDecode(from: output)
  }
}

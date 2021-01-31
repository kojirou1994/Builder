import XCTest

import BuilderSystemTests

var tests = [XCTestCaseEntry]()
tests += BuilderSystemTests.__allTests()

XCTMain(tests)

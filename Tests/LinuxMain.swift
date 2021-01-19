import XCTest

import BuilderTests

var tests = [XCTestCaseEntry]()
tests += BuilderTests.allTests()
XCTMain(tests)

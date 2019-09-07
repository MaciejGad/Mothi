import XCTest

import MothiTests
import MothiExampleTests
import YggdrasilTests

var tests = [XCTestCaseEntry]()
tests += MothiTests.allTests()
tests += MothiExampleTests.allTests()
tests += YggdrasilTests.allTests()
XCTMain(tests)

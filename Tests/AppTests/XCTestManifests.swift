import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FileCollection.allTests),
        testCase(UserCollection.allTests)
    ]
}
#endif

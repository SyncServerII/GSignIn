import XCTest
@testable import FakeExample

final class FakeExampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FakeExample().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

import XCTVapor
@testable import App

final class AppTests: XCTestCase {

    func testFileLoading() throws {

        let app = Application(.testing)
        defer { app.shutdown() }
        try bootstrap(app)

        try app.test(.GET, "resume", afterResponse: {
                XCTAssertEqual($0.status, HTTPStatus.ok)
            })
            .test(.GET, "", afterResponse: {
                XCTAssertEqual($0.status, HTTPStatus.notFound)
            })
    }

    static var allTests = [
        ("testFileLoading", testFileLoading),
    ]
}

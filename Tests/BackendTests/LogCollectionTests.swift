import XCTVapor

@testable import Backend

class LogCollectionTests: XCTestCase {

    private let path = "authorize/basic"

    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        try app.setUp()
        try await app.autoMigrate()
    }

    override func tearDown() {
        XCTAssertNotNil(app)
        app.shutdown()
    }

    func testLoginWithWrongMsg() throws {
        app.registerUserWithLegacy(.generate())

        let wrongPasswordHeader = HTTPHeaders.init(
            dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTEx")
        )
        let wrongUsernameHeader = HTTPHeaders.init(
            dictionaryLiteral: ("Authorization", "Basic dGVzdDE6MTExMTEx")
        )

        try app.test(
            .POST,
            path,
            headers: wrongPasswordHeader,
            afterResponse: {
                XCTAssertEqual($0.status, .unauthorized)
            }
        )
        .test(
            .POST,
            path,
            headers: wrongUsernameHeader,
            afterResponse: {
                XCTAssertEqual($0.status, .unauthorized)
            }
        )
    }

    func testLogin() throws {
        app.login()
    }
}

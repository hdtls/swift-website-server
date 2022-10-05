import XCTVapor

@testable import Backend

class LogCollectionTests: XCTestCase {

    private let path = "authorize/basic"

    func testLoginWithWrongMsg() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

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
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        app.login()
    }
}

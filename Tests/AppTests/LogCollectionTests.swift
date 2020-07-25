import XCTVapor
@testable import App

class LogCollectionTests: XCTestCase {

    let app = Application.init(.testing)
    let path = "login"

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testLoginWithWrongMsg() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        let wrongPasswordHeader = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTEx"))
        let wrongUsernameHeader = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDE6MTExMTEx"))

        try app.test(.POST, path, headers: wrongPasswordHeader, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.POST, path, headers: wrongUsernameHeader, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        })
    }

    func testLogin() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTE="
        ))
        try app.test(.POST, path, headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        })
    }
}

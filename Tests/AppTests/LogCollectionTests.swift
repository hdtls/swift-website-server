import XCTVapor
@testable import App

class LogCollectionTests: XCAppCase {

    let path = "login"

    func testLoginWithWrongMsg() throws {
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
        try registUserAndLoggedIn(app)

        let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTE="
        ))
        try app.test(.POST, path, headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        })
    }
}

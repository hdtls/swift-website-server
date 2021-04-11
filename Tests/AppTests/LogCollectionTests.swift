import XCTVapor
@testable import App

class LogCollectionTests: XCTestCase {

    let path = "login"
    var app: Application!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = .init(.testing)
        try bootstrap(app)
    }

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
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )
        
        try registUserAndLoggedIn(app, userCreation, headers: nil)
        
        let credentials = "\(userCreation.username):\(userCreation.password)".data(using: .utf8)!.base64EncodedString()
        
        let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic \(credentials)"
        ))
        try app.test(.POST, path, headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        })
    }
}

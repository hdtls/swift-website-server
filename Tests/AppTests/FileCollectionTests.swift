import XCTVapor
@testable import App

class FileCollectionTests: XCTestCase {

    let file = File(data: "HELLO WORLD!!!", filename: "hello.txt")
    let path = "files"
    
    var app: Application!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = .init(.testing)
        try bootstrap(app)
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
                .test(.GET, path + "/1", afterResponse: assertHttpNotFound)
        )
    }

    func testCreate() throws {
        try app.test(.POST, path, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(["file" : file], as: .formData)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let content = try $0.content.decode(MultipartFileCoding.self)
            XCTAssertNotNil(content.url)
        })
    }

    func testQuery() throws {
        var url: String!

        try app.test(.POST, path, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(["file" : file], as: .formData)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let content = try $0.content.decode(MultipartFileCoding.self)
            XCTAssertNotNil(content.url)
            url = content.url
        })

        try app.test(.GET, (url.path ?? ""), afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNotNil($0.body)
        })
    }
}

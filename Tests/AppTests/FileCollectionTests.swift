import XCTVapor
@testable import App

class FileCollectionTests: XCAppCase {

    let file = File(data: "HELLO WORLD!!!", filename: "hello.txt")
    let path = "files"

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
                .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpNotFound)
        )
    }

    func testCreate() throws {

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(["file" : file], as: .formData)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNotNil($0.body.string)
            XCTAssertContains($0.body.string, "/static/")
        })
    }

    func testQuery() throws {
        let headers = try registUserAndLoggedIn(app)
        var url: String!

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(["file" : file], as: .formData)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            url = $0.body.string
            XCTAssertNotNil($0.body.string)
        })

        try app.test(.GET, (url.path ?? ""), afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNotNil($0.body)
        })
    }
}

import XCTVapor
@testable import App

class FileCollectionTests: XCAppCase {

    struct MultipartFormData: Encodable {
        var multipart: [String]
    }
    let multipartFormData = MultipartFormData.init(multipart: ["picture.jpg"])
    let path = "images"

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpServerError)
        )
    }

    func testCreate() throws {
        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(multipartFormData, using: FormDataEncoder.init())
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let urls = try $0.content.decode([String].self)
            XCTAssertEqual(urls.count, 1)
        })
    }

    func testQuery() throws {
        let headers = try registUserAndLoggedIn(app)
        var url: String!

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(multipartFormData, using: FormDataEncoder.init())
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let urls = try $0.content.decode([String].self)
            XCTAssertEqual(urls.count, 1)
            url = urls.first!
        })

        try app.test(.GET, (url.path ?? ""), afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNotNil($0.body)
        })
    }
}

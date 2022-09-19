import XCTVapor

@testable import Backend

class FileCollectionTests: XCTestCase {

    private let file = File(data: "HELLO WORLD!!!", filename: "hello.txt")
    private let uri = "files"

    func testAuthorizeRequire() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        XCTAssertNoThrow(
            try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.GET, uri + "/1", afterResponse: assertHTTPStatusEqualToNotFound)
        )
    }

    func testCreateFile() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(
            .POST,
            uri,
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(["file": file], as: .formData)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let content = try $0.content.decode(FileURL.self)
                XCTAssertNotNil(content.url)
            }
        )
    }

    func testQueryFile() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }
        
        var url: String!

        try app.test(
            .POST,
            uri,
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(["file": file], as: .formData)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let content = try $0.content.decode(FileURL.self)
                XCTAssertNotNil(content.url)
                url = content.url
            }
        )
        .test(
            .GET,
            URL(string: url)!.path,
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                XCTAssertNotNil($0.body)
            }
        )
    }
}

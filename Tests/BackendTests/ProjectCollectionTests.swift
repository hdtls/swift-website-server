import XCTVapor
import XCTest

@testable import Backend

class ProjectCollectionTests: XCTestCase {

    private typealias Model = Project.DTO
    private let uri = Project.schema
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

    func testAuthorizeRequire() throws {
        try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
            .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
            .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
            .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
    }

    func testCreateProject() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            uri,
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Model.self)
                expected.id = model.id
                expected.userId = model.userId
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testQueryProjectWithInvalidID() throws {
        try app.test(
            .GET,
            uri + "/invalid",
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testQueryProjectWithSpecifiedID() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            uri,
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                expected = try $0.content.decode(Model.self)
            }
        )
        .test(
            .GET,
            uri + "/\(expected.id)",
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let model = try $0.content.decode(Model.self)
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testUpdateProject() throws {
        var original = Model.generate()
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            uri,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(original)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                original = try $0.content.decode(Model.self)
            }
        )
        .test(
            .PUT,
            uri + "/\(original.id)",
            headers: headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Model.self)
                expected.id = model.id
                expected.userId = model.userId
                XCTAssertEqual(model, expected)
                XCTAssertEqual(expected.id, original.id)
            }
        )
    }

    func testDeleteProjectWithInvalidID() throws {
        try app.test(
            .DELETE,
            uri + "/invalid",
            headers: app.login().headers,
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testDeleteProject() throws {
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            uri,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                expected = try $0.content.decode(Model.self)
            }
        )
        .test(
            .DELETE,
            uri + "/\(expected.id)",
            headers: headers,
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(.GET, uri + "/\(expected.id)", afterResponse: assertHTTPStatusEqualToNotFound)
    }
}

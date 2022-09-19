import XCTVapor
import XCTest

@testable import Backend

class ProjectCollectionTests: XCTestCase {

    private typealias Model = Project.DTO
    private let uri = Project.schema

    func testAuthorizeRequire() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
            .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
            .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
            .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
    }

    func testCreateProject() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

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
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(.GET, uri + "/invalid", afterResponse: assertHTTPStatusEqualToUnprocessableEntity)
    }

    func testQueryProjectWithSpecifiedID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

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
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

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
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(
            .DELETE,
            uri + "/invalid",
            headers: app.login().headers,
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testDeleteProject() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }
        
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

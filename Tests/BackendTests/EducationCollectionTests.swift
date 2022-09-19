import XCTVapor

@testable import Backend

class EducationCollectionTests: XCTestCase {

    private typealias Model = Education.DTO
    private let uri = Education.schema

    func testAuthorizeRequire() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        XCTAssertNoThrow(
            try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
                .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateEducation() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var expected = Model.generate()

        let msg = app.login()

        try app.test(
            .POST,
            uri,
            headers: msg.headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Model.self)
                expected.id = model.id
                expected.userId = msg.user.id
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testQueryEducationWithInvalidEduID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        XCTAssertNoThrow(
            try app.test(.GET, uri + "/invalid", afterResponse: assertHTTPStatusEqualToUnprocessableEntity)
        )
    }

    func testQueryEducationWithSpecifiedID() throws {
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
                let model = try $0.content.decode(Education.DTO.self)
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testUpdateEducation() throws {
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
                try $0.content.encode(expected)
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
                let model = try $0.content.decode(Education.DTO.self)
                expected.id = model.id
                expected.userId = model.userId
                XCTAssertEqual(model, expected)
                XCTAssertEqual(expected.id, original.id)
            }
        )
    }

    func testDeleteEducationWithInvalideduID() throws {
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

    func testDeleteEducationWithSpecifiedID() throws {
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

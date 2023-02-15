import XCTVapor

@testable import Backend

class SkillCollectionTests: XCTestCase {

    private typealias Model = Skill.DTO
    private let uri = Skill.schema
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
        XCTAssertNoThrow(
            try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(
                    .GET,
                    uri + "/invalid",
                    afterResponse: assertHTTPStatusEqualToUnprocessableEntity
                )
                .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateSkill() throws {
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
                let model = try $0.content.decode(Model.self)
                expected.id = model.id
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testQuerySkillWithSpecifiedID() throws {
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

    func testQuerySkillWithInvalidID() throws {
        try app.test(
            .GET,
            uri + "/invalid",
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testUpdateSkill() throws {
        var original = Model.generate()
        let headers = app.login().headers
        var expected = original
        expected.professional.append(.random(length: 12))

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
                XCTAssertEqual(model, expected)
                XCTAssertEqual(expected.id, original.id)
            }
        )
    }

    func testUpdateSkillWithInvalidID() throws {
        try app.test(
            .PUT,
            uri + "/invalid",
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(Model.generate())
            },
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testDeleteSkillWithSpecifiedID() throws {
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
        .test(
            .GET,
            uri + "/\(expected.id)",
            afterResponse: assertHTTPStatusEqualToNotFound
        )
        .test(
            .DELETE,
            uri + "/invalid",
            headers: headers,
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }
}

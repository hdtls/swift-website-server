import XCTVapor

@testable import Backend

class ExpCollectionTests: XCTestCase {

    private typealias Model = Experience.DTO
    private let uri = Experience.schema
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
                .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
                .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateExperience() throws {
        var expected = Model.generate()
        try app.test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Industry.DTO.self)
                expected.industries = [model]
            }
        )
        .test(
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

    func testQueryExperienceWithInvalidWorkID() throws {
        XCTAssertNoThrow(
            try app.test(
                .GET,
                uri + "/invalid",
                afterResponse: assertHTTPStatusEqualToUnprocessableEntity
            )
        )
    }

    func testQueryExperienceWithSpecifiedID() throws {
        var expected = Model.generate()
        try app.test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Industry.DTO.self)
                expected.industries = [model]
            }
        )
        .test(
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

    func testUpdateExperience() throws {
        var original = Model.generate()
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Industry.DTO.self)
                expected.industries = [model]
            }
        )
        .test(
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

    func testDeleteExperienceWithInvalidID() throws {
        try app.test(
            .DELETE,
            uri + "/invalid",
            headers: app.login().headers,
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testDeleteExperienceWithSpecifiedID() throws {
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(Industry.DTO.self)
                expected.industries = [model]
            }
        )
        .test(
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

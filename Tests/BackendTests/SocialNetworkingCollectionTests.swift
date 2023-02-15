import XCTVapor

@testable import Backend

class SocialNetworkingCollectionTests: XCTestCase {

    typealias Model = SocialNetworking.DTO
    private let uri = SocialNetworking.schema
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
                .test(.GET, uri, afterResponse: assertHTTPStatusEqualToOk)
                .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateSocialNetworking() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(SocialNetworkingService.DTO.self)
                expected.serviceId = model.id
                expected.service = model
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

    func testQuerySocialNetworkingWithInvalidID() throws {
        XCTAssertNoThrow(
            try app.test(
                .GET,
                uri + "/invalid",
                afterResponse: assertHTTPStatusEqualToUnprocessableEntity
            )
        )
    }

    func testQuerySocialNetworkingWithSpecifiedID() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(SocialNetworkingService.DTO.self)
                expected.serviceId = model.id
                expected.service = model
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

    func testUpdateSocialNetworking() throws {
        var original = Model.generate()
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(SocialNetworkingService.DTO.self)
                original.serviceId = model.id
                original.service = model
                expected.serviceId = model.id
                expected.service = model
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

    func testDeleteSocialNetowrking() throws {
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(SocialNetworkingService.DTO.self)
                expected.serviceId = model.id
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

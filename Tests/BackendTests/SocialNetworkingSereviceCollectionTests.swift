import XCTVapor

@testable import Backend

class SocialNetworkingSereviceCollectionTests: XCTestCase {

    private typealias Model = SocialNetworkingService.DTO
    private let uri = "\(SocialNetworking.schema)/services"
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

    func testCreateSNS() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            uri,
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

    func testQuerySNSWithInvalidID() throws {
        try app.test(
            .GET,
            uri + "/invalid",
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testQuerySNSWithSpecifiedID() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            uri,
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

    func testUpdateSNS() throws {
        var original = Model.generate()
        var expected = original
        expected.name = .random(length: 8)

        try app.test(
            .POST,
            uri,
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

    func testDeleteSNSWithInvalidServiceID() throws {
        try app.test(
            .DELETE,
            uri + "/invalid",
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testDeleteSNSWithSpecifiedID() throws {
        var expected = Model.generate()

        try app.test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                expected = try $0.content.decode(Model.self)
            }
        )
        .test(.DELETE, uri + "/\(expected.id)", afterResponse: assertHTTPStatusEqualToOk)
        .test(.GET, uri + "/\(expected.id)", afterResponse: assertHTTPStatusEqualToNotFound)
    }
}

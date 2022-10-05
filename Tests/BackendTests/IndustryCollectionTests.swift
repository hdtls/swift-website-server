import XCTVapor

@testable import Backend

class IndustryCollectionTests: XCTestCase {

    private typealias Model = Industry.DTO
    private let uri = Industry.schema

    func testCreateIndustry() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var expected = Model.generate()

        XCTAssertNoThrow(
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
        )
    }

    func testUniqueIndustryTitle() throws {
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
        .test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .unprocessableEntity)
            }
        )
    }

    func testQueryIndustryWithInvalidID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(
            .GET,
            uri + "/invalid",
            afterResponse: assertHTTPStatusEqualToUnprocessableEntity
        )
    }

    func testQueryIndustryWithSpecifiedID() throws {
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

    func testQueryAllIndustries() throws {
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
        .test(
            .GET,
            uri,
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let models = try $0.content.decode([Model].self)
                XCTAssertGreaterThanOrEqual(models.count, 1)
                XCTAssertTrue(models.contains(expected))
            }
        )
    }

    func testUpdateIndustry() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var original = Model.generate()
        var expected = Model.generate()

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
                XCTAssertNotNil(model.id)
                expected.id = model.id

                XCTAssertEqual(model, expected)
                XCTAssertEqual(expected.id, original.id)
            }
        )
    }

    func testDeleteIndustryWithSpecifiedID() throws {
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
        .test(.DELETE, uri + "/invalid", afterResponse: assertHTTPStatusEqualToUnprocessableEntity)
    }
}

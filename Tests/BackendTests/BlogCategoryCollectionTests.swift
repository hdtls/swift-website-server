import XCTVapor

@testable import Backend

class BlogCategoryCollectionTests: XCTestCase {
    
    private typealias Model = BlogCategory.DTO
    private let uri = BlogCategory.schema

    func testCreateBlogCategory() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }
        let encodable = Model.generate()
        XCTAssertNoThrow(
            try app.test(
                .POST,
                uri,
                beforeRequest: {
                    try $0.content.encode(encodable)
                },
                afterResponse: {
                    XCTAssertEqual($0.status, .ok)
                    let model = try $0.content.decode(Model.self)
                    XCTAssertEqual(model.name, encodable.name)
                }
            )
        )
    }
    
    func testUniqueBlogCategoryName() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        let encodable = Model.generate()
        
        try app.test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(encodable)
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(encodable)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .unprocessableEntity)
                XCTAssertContains($0.body.string, "Duplicate entry")
            }
        )
    }
    
    func testPayloadFieldsRequirement() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        let json: [String: String] = [:]
        try app.test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(json)
            },
            afterResponse: assertHTTPStatusEqualToBadRequest
        )
    }
    
    func testQueryBlogCategoryWithIDThatDoesNotExsit() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
    }
    
    func testQueryBlogCategoryWithSpecifiedID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        let encodable = Model.generate()
        var expected: Model = .generate()
        
        try app.test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(encodable)
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
    
    func testQueryAllBlogCategories() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var expected: Model = .generate()
        
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
            uri,
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let models = try $0.content.decode([Model].self)
                XCTAssertNotNil(models)
                XCTAssertGreaterThanOrEqual(models.count, 1)
                XCTAssertTrue(models.contains(expected))
            }
        )
    }
    
    func testUpdateBlogCategory() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var original: Model = .generate()
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
                expected.id = model.id
                XCTAssertEqual(expected, model)
                XCTAssertEqual(original.id, model.id)
            }
        )
    }
    
    func testDeleteBlogCategoryWithIDThatDoesNotExsit() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(
            .DELETE,
            uri + "/0",
            afterResponse: assertHTTPStatusEqualToOk
        )
    }
    
    func testDeleteBlogCategoryWithSpecifiedID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }
        
        var expected: Model = .generate()
        
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

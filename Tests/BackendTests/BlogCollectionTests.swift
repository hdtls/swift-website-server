import XCTVapor

@testable import Backend

class BlogCollectionTests: XCTestCase {

    private typealias Model = Blog.DTO
    private let uri = Blog.schema

    func testAuthorizeRequire() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        XCTAssertNoThrow(
            try app.test(.POST, uri, afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.GET, uri, afterResponse: assertHTTPStatusEqualToOk)
                .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
                .test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
                .test(.DELETE, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateBlog() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var expected = Model.generate()

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
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

    func testCreateBlogWithoutContent() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var expected = Model.generate()
        expected.content = nil

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
            }
        )
        .test(
            .POST,
            Blog.schema,
            headers: app.login().headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .unprocessableEntity)
                XCTAssertContains($0.body.string, "Value required for key 'content'")
            }
        )
    }

    func testQueryBlogWithIDThatDoesNotExsit() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        XCTAssertNoThrow(
            try app.test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
        )
    }

    func testQueryBlogWithSpecifiedID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var expected = Model.generate()

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
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

    func testUpdateBlog() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var original = Model.generate()
        var expected = original
        expected.title = .random(length: 8)
        expected.excerpt = .random(length: 4)
        expected.tags = [.random(length: 4)]
        expected.content = .random(length: 23)

        let headers = app.login().headers

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
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

    func testUpdateBlogWithNewCategory() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var original = Model.generate()
        var expected = original
        expected.title = .random(length: 8)
        expected.excerpt = .random(length: 4)
        expected.tags = [.random(length: 4)]
        expected.content = .random(length: 23)

        let headers = app.login().headers

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
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
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(BlogCategory.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [model]
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

    func testUpdateBlogWithRemoveCategory() throws {
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
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(BlogCategory.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(BlogCategory.DTO.self)
                original.categories.append(model)
            }
        )
        .test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(BlogCategory.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let model = try $0.content.decode(BlogCategory.DTO.self)
                original.categories.append(model)
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
                expected = original
                _ = expected.categories.removeLast()
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
                XCTAssertEqual(model, expected)
                _ = original.categories.removeLast()
                XCTAssertEqual(original, expected)
            }
        )
    }

    func testUpdateBlogAlias() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var original = Model.generate()
        var expected = original
        expected.alias = .random(length: 14)

        let headers = app.login().headers

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                original.categories = [category]
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

    func testDeleteBlogWithIDThatDoesNotExsit() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        try app.test(
            .DELETE,
            uri + "/" + "0",
            headers: app.login().headers,
            afterResponse: assertHTTPStatusEqualToOk
        )
    }

    func testDeleteBlogWithSpecifiedID() throws {
        let app = Application(.testing)
        try bootstrap(app)
        try app.autoMigrate().wait()
        defer {
            app.shutdown()
        }

        var category = BlogCategory.DTO.generate()
        var expected = Model.generate()

        let headers = app.login().headers

        try app.test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(category)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                category = try $0.content.decode(BlogCategory.DTO.self)
                expected.categories = [category]
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
        .test(.GET, uri + "\(expected.id)", afterResponse: assertHTTPStatusEqualToNotFound)
    }
}

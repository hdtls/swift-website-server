import XCTVapor
@testable import App

@discardableResult
func assertCreateBlog(
    _ app: Application,
    blog: Blog.SerializedObject? = nil,
    headers: HTTPHeaders? = nil
) throws -> Blog.SerializedObject {
    let headers = try registUserAndLoggedIn(app, headers: headers)

    var blog = blog

    if blog == nil {
        let category = try assertCreateBlogCategory(app, headers: headers)
        blog = Blog.SerializedObject.init(alias: UUID().uuidString, title: "Hello Vapor", excerpt: "", content: "", categories: [category])
    }

    var coding: Blog.SerializedObject!

    try app.test(.POST, Blog.schema, headers: headers, beforeRequest: {
        try $0.content.encode(blog!)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Blog.SerializedObject.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.alias, blog?.alias)
        XCTAssertEqual(coding.title, blog?.title)
        XCTAssertEqual(coding.artworkUrl, blog?.artworkUrl)
        XCTAssertEqual(coding.excerpt, blog?.excerpt)
        XCTAssertEqual(coding.tags, blog?.tags)
        XCTAssertEqual(coding.content, blog?.content)
        XCTAssertEqual(coding.categories.count, blog?.categories.count)
        XCTAssertNotNil(coding.createdAt)
        XCTAssertNotNil(coding.updatedAt)
    })

    return coding
}

class BlogCollectionTests: XCTestCase {

    let path = Blog.schema
    var app: Application!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = .init(.testing)
        try bootstrap(app)
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }

    func testAuthorizeRequire() {
        let uuid = UUID.init().uuidString

        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
                .test(.GET, path, afterResponse: assertHttpOk)
                .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
                .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
                .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)
        try _deleteBlog(blog, headers: headers)
    }

    func testCreateWithoutContent() throws {
        let blog = Blog.Coding.init(alias: "hello-vapor", title: "Hello Vapor", excerpt: "", categories: [])

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, Blog.schema, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
            XCTAssertContains($0.body.string, "Value required for key 'content'")
        })
    }

    func testQueryWithIDThatDoesNotExsit() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)
        XCTAssertNoThrow(try app.test(.GET, path + "/\(UUID())", afterResponse: assertHttpNotFound))
        try _deleteBlog(blog, headers: headers)
    }

    func testQueryWithID() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)

        try app.test(.GET, path + "/\(blog.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding, blog)
        })

        try _deleteBlog(blog, headers: headers)
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)

        var blog = try assertCreateBlog(app, headers: headers)
        blog.title = "Hello world!!!"
        blog.excerpt = "Hello world."
        blog.tags = ["greeting"]
        blog.content = "Content of hello world"

        try app.test(.PUT, path + "/" + blog.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories, blog.categories)
        })

        try _deleteBlog(blog, headers: headers)
    }

    func testUpdateBlogWithNewCategory() throws {
        let headers = try registUserAndLoggedIn(app)

        var blog = try assertCreateBlog(app, headers: headers)
        let category = try assertCreateBlogCategory(app, headers: headers)
        blog.categories.append(category)

        try app.test(.PUT, path + "/" + blog.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })

        try _deleteBlog(blog, headers: headers)
    }

    func testUpdateBlogWithRemoveCategory() throws {
        let headers = try registUserAndLoggedIn(app)

        let category1 = try assertCreateBlogCategory(app, headers: headers)
        let category2 = try assertCreateBlogCategory(app, headers: headers)
        let category3 = try assertCreateBlogCategory(app, headers: headers)

        let categories = [category1, category2, category3]

        var blog: Blog.SerializedObject = .init(
            alias: "test",
            title: "test",
            excerpt: "test",
            content: "test content",
            categories: categories
        )

        blog = try assertCreateBlog(app, blog: blog, headers: headers)

        try app.test(.PUT, path + "/" + blog.id!.uuidString, headers: headers, beforeRequest: {
            _ = blog.categories.removeLast()
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, 2)
        })

        try app.test(.PUT, path + "/" + blog.alias, headers: headers, beforeRequest: {
            _ = blog.categories.removeLast()
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, 1)
        })

        try _deleteBlog(blog, headers: headers)
    }

    func testUpdateBlogAlias() throws {
        let headers = try registUserAndLoggedIn(app)

        var blog = try assertCreateBlog(app, headers: headers)
        blog.alias = "update-blog-alias"

        try app.test(.PUT, path + "/" + blog.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })

        try app.test(.PUT, path + "/" + blog.alias, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createdAt, blog.createdAt)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })

        try _deleteBlog(blog, headers: headers)
    }

    func testDeleteWithIDThatDoesNotExsit() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)

        try app.test(.DELETE, path + "/" + "1", headers: headers, afterResponse: assertHttpNotFound)
        try _deleteBlog(blog, headers: headers)
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)
        try _deleteBlog(blog, headers: headers)
    }

    private func _deleteBlog(_ blog: Blog.SerializedObject, headers: HTTPHeaders) throws {
        try app.test(.DELETE, path + "/" + blog.id!.uuidString, headers: headers, afterResponse: assertHttpOk)
    }
}

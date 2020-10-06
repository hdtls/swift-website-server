import XCTVapor
@testable import App

@discardableResult
func assertCreateBlog(_ app: Application, headers: HTTPHeaders? = nil) throws -> Blog.SerializedObject {

    let blog = Blog.SerializedObject.init(alias: "hello-vapor", title: "Hello Vapor", excerpt: "", content: "")

    let headers = try registUserAndLoggedIn(app, headers: headers)

    var coding: Blog.SerializedObject!

    try app.test(.POST, Blog.schema, headers: headers, beforeRequest: {
        try $0.content.encode(blog)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Blog.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.alias, blog.alias)
        XCTAssertEqual(coding.title, blog.title)
        XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
        XCTAssertEqual(coding.excerpt, blog.excerpt)
        XCTAssertEqual(coding.tags, blog.tags)
        XCTAssertEqual(coding.content, blog.content)
        XCTAssertNotNil(coding.createAt)
        XCTAssertNotNil(coding.updateAt)
    })

    return coding
}

class BlogCollectionTests: XCAppCase {

    let path = Blog.schema

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
        let blog = Blog.Coding.init(alias: "hello-vapor", title: "Hello Vapor", excerpt: "")

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, Blog.schema, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value required for key 'content'")
        })
    }

    func testQueryWithIDThatDoesNotExsit() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
        try _deleteBlog(blog, headers: headers)
    }

    func testQueryWithID() throws {
        let headers = try registUserAndLoggedIn(app)
        let blog = try assertCreateBlog(app, headers: headers)
        try app.test(.GET, path + "/\(blog.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertNotNil(coding.content)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createAt, blog.createAt)
            XCTAssertEqual(coding.updateAt, blog.updateAt)
        })

        try app.test(.GET, path + "/\(blog.alias)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertNotNil(coding.content)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.createAt, blog.createAt)
            XCTAssertEqual(coding.updateAt, blog.updateAt)
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
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.content, blog.content)
        })

        try app.test(.PUT, path + "/" + blog.alias, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.content, blog.content)
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
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.content, blog.content)
        })

        try app.test(.PUT, path + "/" + blog.alias, headers: headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Blog.SerializedObject.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.content, blog.content)
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

import XCTVapor
@testable import App

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
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
                .test(.GET, path, afterResponse: assertHttpOk)
                .test(.GET, path + "/0", afterResponse: assertHttpNotFound)
                .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
                .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }
    
    func testCreate() throws {
        app.requestBlog(.generate())
    }
    
    func testCreateWithoutContent() throws {
        var blog = Blog.Coding.generate()
        blog.content = nil
        
        try app.test(.POST, Blog.schema, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
            XCTAssertContains($0.body.string, "Value required for key 'content'")
        })
    }
    
    func testQueryWithIDThatDoesNotExsit() throws {
        XCTAssertNoThrow(try app.test(.GET, path + "/0", afterResponse: assertHttpNotFound))
    }
    
    func testQueryWithID() throws {
        let blog = app.requestBlog()
        
        try app.test(.GET, path + "/\(blog.id)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding, blog)
        })
    }
    
    func testUpdate() throws {
        var blog = app.requestBlog()
        blog.title = .random(length: 8)
        blog.excerpt = .random(length: 4)
        blog.tags = [.random(length: 4)]
        blog.content = .random(length: 23)
        
        try app.test(.PUT, path + "/\(blog.id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories, blog.categories)
        })
    }
    
    func testUpdateBlogWithNewCategory() throws {
        var blog = app.requestBlog()
        let category = app.requestBlogCategory(.generate())
        blog.categories.append(category)
        
        try app.test(.PUT, path + "/\(blog.id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })
    }
    
    func testUpdateBlogWithRemoveCategory() throws {
        let categories = [
            app.requestBlogCategory(.generate()),
            app.requestBlogCategory(.generate()),
            app.requestBlogCategory(.generate())
        ]
        
        var blog: Blog.DTO = .generate()
        blog.categories += categories
        
        blog = app.requestBlog(blog)
        
        try app.test(.PUT, path + "/\(blog.id)", headers: app.login().headers, beforeRequest: {
            _ = blog.categories.removeLast()
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, 2)
        })
        .test(.PUT, path + "/" + blog.alias, headers: app.login().headers, beforeRequest: {
            _ = blog.categories.removeLast()
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, 1)
        })
    }
    
    func testUpdateBlogAlias() throws {
        var blog = app.requestBlog()
        blog.alias = .random(length: 14)
        
        try app.test(.PUT, path + "/\(blog.id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })
        .test(.PUT, path + "/" + blog.alias, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blog)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Blog.DTO.self)
            XCTAssertEqual(coding.id, blog.id)
            XCTAssertEqual(coding.alias, blog.alias)
            XCTAssertEqual(coding.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(coding.content, blog.content)
            XCTAssertEqual(coding.excerpt, blog.excerpt)
            XCTAssertEqual(coding.tags, blog.tags)
            XCTAssertEqual(coding.title, blog.title)
            XCTAssertEqual(coding.userId, blog.userId)
            XCTAssertEqual(coding.categories.count, blog.categories.count)
        })
    }
    
    func testDeleteWithIDThatDoesNotExsit() throws {
        try app.test(.DELETE, path + "/" + "0", headers: app.login().headers, afterResponse: assertHttpNotFound)
    }
    
    func testDelete() throws {
        try app.test(.DELETE, path + "/\(app.requestBlog(.generate()).id)", headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

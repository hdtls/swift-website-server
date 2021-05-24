import XCTVapor
@testable import App

class BlogCategoryCollectionTests: XCTestCase {

    typealias T = BlogCategory
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

    func testCreate() throws {
        app.requestBlogCategory(.generate())
    }

    func testCreateWithDuplicateName() throws {
        let expected = app.requestBlogCategory()
        let blogCategory = BlogCategory.SerializedObject.generate()
        blogCategory.name = expected.name
        
        try app.test(.POST, T.schema, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(blogCategory)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
            XCTAssertContains($0.body.string, "Duplicate entry")
        })
    }

    func testCreateWithoutName() throws {
        let json: [String : String] = [:]
        try app.test(.POST, T.schema, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: assertHttpBadRequest)
    }

    func testQueryWithIDThatDoesNotExsit() throws {
        try app.test(.GET, T.schema + "/\(UUID().uuidString)", afterResponse: assertHttpNotFound)
    }

    func testQueryWithID() throws {
        let serialized = app.requestBlogCategory()

        try app.test(.GET, T.schema + "/\(serialized.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(T.SerializedObject.self)
            XCTAssertEqual(serialized, coding)
        })
    }

    func testQueryAll() throws {
        app.requestBlogCategory()
        
        try app.test(.GET, T.schema, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([T.SerializedObject].self)
            XCTAssertNotNil(coding)
            XCTAssertGreaterThanOrEqual(coding.count, 1)
        })
    }

    func testUpdate() throws {
        let expected = T.SerializedObject.generate()
        
        try app.test(.PUT, T.schema + "/\(app.requestBlogCategory().id!)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(expected)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(T.SerializedObject.self)
            expected.id = coding.id
            XCTAssertEqual(expected, coding)
        })
    }

    func testDeleteWithIDThatDoesNotExsit() throws {
        try app.test(.DELETE, BlogCategory.schema + "/\(UUID())", headers: app.login().headers, afterResponse: assertHttpNotFound)
    }

    func testDeleteWithID() throws {
        let serialized = app.requestBlogCategory(.generate())
        try app.test(.DELETE, BlogCategory.schema + "/\(serialized.id!)", headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

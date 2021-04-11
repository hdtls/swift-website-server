import XCTVapor
@testable import App

@discardableResult
func assertCreateBlogCategory(
    _ app: Application,
    category: BlogCategory.SerializedObject = .init(id: nil, name: String(UUID().uuidString.prefix(4))),
    headers: HTTPHeaders? = nil) throws -> BlogCategory.SerializedObject {

    let headers = try registUserAndLoggedIn(app, headers: headers)

    var coding: BlogCategory.SerializedObject!

    try app.test(.POST, BlogCategory.schema, headers: headers, beforeRequest: {
        try $0.content.encode(category)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(BlogCategory.SerializedObject.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.name, category.name)
    })

    return coding
}

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
        let json = ["name" : UUID().uuidString]
        let headers = try registUserAndLoggedIn(app)
        try app.test(.POST, T.schema, headers: headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(T.SerializedObject.self)
            XCTAssertNotNil(coding.id)
            XCTAssertEqual(coding.name, json["name"])
        })
    }

    func testCreateWithDuplicateName() throws {
        let headers = try registUserAndLoggedIn(app)

        let category = try assertCreateBlogCategory(app, headers: headers)

        try app.test(.POST, T.schema, headers: headers, beforeRequest: {
            try $0.content.encode(category)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
            XCTAssertContains($0.body.string, "Duplicate entry")
        })
    }

    func testCreateWithoutName() throws {
        let json: [String : String] = [:]
        let headers = try registUserAndLoggedIn(app)
        try app.test(.POST, T.schema, headers: headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: assertHttpBadRequest)
    }

    func testQueryWithIDThatDoesNotExsit() throws {
        try app.test(.GET, T.schema + "/\(UUID().uuidString)", afterResponse: assertHttpNotFound)
    }

    func testQueryWithID() throws {
        let serialized = try assertCreateBlogCategory(app)

        try app.test(.GET, T.schema + "/\(serialized.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(T.SerializedObject.self)
            XCTAssertEqual(serialized, coding)
        })
    }

    func testQueryAll() throws {
        try assertCreateBlogCategory(app)

        try app.test(.GET, T.schema, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([T.SerializedObject].self)
            XCTAssertNotNil(coding)
        })
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)

        let serialized = try assertCreateBlogCategory(app, headers: headers)
        let upgrade = serialized
        upgrade.name = String(UUID().uuidString.prefix(4))

        try app.test(.PUT, T.schema + "/\(serialized.id!)", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(T.SerializedObject.self)
            XCTAssertEqual(upgrade, coding)
        })
    }

    func testDeleteWithIDThatDoesNotExsit() throws {
        let headers = try registUserAndLoggedIn(app)

        try app.test(.DELETE, BlogCategory.schema + "/\(UUID())", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDeleteWithID() throws {
        let headers = try registUserAndLoggedIn(app)
        let serialized = try assertCreateBlogCategory(app, headers: headers)
        try app.test(.DELETE, BlogCategory.schema + "/\(serialized.id!)", headers: headers, afterResponse: assertHttpOk)
    }
}

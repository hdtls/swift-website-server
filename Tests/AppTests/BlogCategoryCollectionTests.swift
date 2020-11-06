import XCTVapor
@testable import App

func assertCreateBlogCategory(_ app: Application, headers: HTTPHeaders? = nil) throws -> BlogCategory.SerializedObject {
    let category = BlogCategory.SerializedObject.init(id: nil, name: "swift")

    let headers = try registUserAndLoggedIn(app, headers: headers)

    var coding: BlogCategory.SerializedObject!

    try app.test(.POST, BlogCategory.schema, headers: headers, beforeRequest: {
        try $0.content.encode(category)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(BlogCategory.SerializedObject.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.name, coding.name)
    })

    return coding
}

class BlogCategoryCollectionTests: XCAppCase {

    typealias T = BlogCategory

    func testCreate() throws {
        let json = ["name" : "swift"]
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
        let serialized = try assertCreateBlogCategory(app)

        try app.test(.GET, T.schema, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([T.SerializedObject].self)
            XCTAssertEqual(coding.count, 1)
            XCTAssertEqual(serialized, coding.first)
        })
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)

        let serialized = try assertCreateBlogCategory(app, headers: headers)
        let upgrade = serialized
        upgrade.name = "server side swift"

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

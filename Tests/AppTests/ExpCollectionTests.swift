import XCTVapor
@testable import App

class ExpCollectionTests: XCTestCase {

    let path = Experience.schema
    
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
//            .test(.GET, path, afterResponse: assertHttpNotFound)
            .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() {
        XCTAssertNoThrow(try assertCreateWorkExperiance(app))
    }

    func testQueryWithInvalidWorkID() {
        XCTAssertNoThrow(try assertCreateWorkExperiance(app))
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
    }

    func testQueryWithWorkID() throws {
        let exp = try assertCreateWorkExperiance(app)

        try app.test(.GET, path + "/\(exp.id!.uuidString)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Experience.SerializedObject.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, exp.title)
            XCTAssertEqual(coding.companyName, exp.companyName)
            XCTAssertEqual(coding.location, exp.location)
            XCTAssertEqual(coding.startDate, exp.startDate)
            XCTAssertEqual(coding.endDate, exp.endDate)
            XCTAssertEqual(coding.industries.count, 1)
            XCTAssertNotNil(coding.industries.first!.id)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)

        let exp = try assertCreateWorkExperiance(app, headers: headers)

        let upgrade = Experience.SerializedObject.init(
            title: exp.title,
            companyName: exp.companyName,
            location: exp.location,
            startDate: exp.startDate,
            endDate: "2020-06-29",
            industries: []
        )

        try app.test(.PUT, path + "/" + exp.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Experience.SerializedObject.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, upgrade.title)
            XCTAssertEqual(coding.companyName, upgrade.companyName)
            XCTAssertEqual(coding.location, upgrade.location)
            XCTAssertEqual(coding.startDate, upgrade.startDate)
            XCTAssertEqual(coding.endDate, upgrade.endDate)
            XCTAssertEqual(coding.industries.count, 0)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        let headers = try registUserAndLoggedIn(app)

        try assertCreateWorkExperiance(app, headers: headers)

        try app.test(.DELETE, path + "/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)

        let exp = try assertCreateWorkExperiance(app, headers: headers)

        try app.test(.DELETE, path + "/\(exp.id!.uuidString)", headers: headers, afterResponse: assertHttpOk)
    }
}

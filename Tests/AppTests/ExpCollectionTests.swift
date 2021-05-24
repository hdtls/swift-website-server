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
            .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() {
        var expected = Experience.SerializedObject.generate()
        expected.industries = [app.requestIndustry(.generate())]
        app.requestJobExperience(expected)
    }

    func testQueryWithInvalidWorkID() {
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
    }

    func testQueryWithWorkID() throws {
        let exp = app.requestJobExperience()
        try app.test(.GET, path + "/\(exp.id!.uuidString)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Experience.SerializedObject.self)
            XCTAssertEqual(coding, exp)
        })
    }

    func testUpdate() throws {
        let upgrade = Experience.SerializedObject.generate()

        try app.test(.PUT, path + "/" + app.requestJobExperience().id!.uuidString, headers: app.login().headers, beforeRequest: {
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
            XCTAssertEqual(coding.headline, upgrade.headline)
            XCTAssertEqual(coding.responsibilities, upgrade.responsibilities)
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        try app.test(.DELETE, path + "/1", headers: app.login().headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let exp = app.requestJobExperience(.generate())

        try app.test(.DELETE, path + "/\(exp.id!.uuidString)", headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

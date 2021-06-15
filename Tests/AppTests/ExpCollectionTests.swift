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
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/0", afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() {
        var expected = Experience.DTO.generate()
        expected.industries = [app.requestIndustry(.generate())]
        app.requestJobExperience(expected)
    }

    func testQueryWithInvalidWorkID() {
        XCTAssertNoThrow(try app.test(.GET, path + "/invalid", afterResponse: assertHttpUnprocessableEntity))
    }

    func testQueryWithWorkID() throws {
        let exp = app.requestJobExperience()
        try app.test(.GET, path + "/\(exp.id)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Experience.DTO.self)
            XCTAssertEqual(coding, exp)
        })
    }

    func testUpdate() throws {
        let upgrade = Experience.DTO.generate()

        try app.test(.PUT, path + "/\(app.requestJobExperience().id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Experience.DTO.self)

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
        try app.test(.DELETE, path + "/invalid", headers: app.login().headers, afterResponse: assertHttpUnprocessableEntity)
    }

    func testDelete() throws {
        let exp = app.requestJobExperience(.generate())

        try app.test(.DELETE, path + "/\(exp.id)", headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

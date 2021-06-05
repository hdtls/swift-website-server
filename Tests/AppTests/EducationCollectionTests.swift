import XCTVapor
@testable import App

class EducationCollectionTests: XCTestCase {

    let path = Education.schema
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
        app.requestEducation(.generate())
    }

    func testQueryWithInvalidEduID() {
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
    }

    func testQueryWithEduID() throws {
        let exp = app.requestEducation()

        try app.test(.GET, path + "/" + exp.id.uuidString, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Education.Coding.self)
            XCTAssertEqual(coding.id, exp.id)
            XCTAssertEqual(coding.userId, exp.userId)
            XCTAssertEqual(coding.school, exp.school)
            XCTAssertEqual(coding.degree, exp.degree)
            XCTAssertEqual(coding.field, exp.field)
            XCTAssertEqual(coding.startYear, exp.startYear)
            XCTAssertEqual(coding.endYear, exp.endYear)
            XCTAssertEqual(coding.activities, exp.activities)
            XCTAssertEqual(coding.accomplishments, exp.accomplishments)
        })
    }

    func testUpdate() throws {
        let exp = app.requestEducation()
        let upgrade = Education.DTO.generate()
        
        try app.test(.PUT, path + "/" + exp.id.uuidString, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Education.DTO.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.school, upgrade.school)
            XCTAssertEqual(coding.degree, upgrade.degree)
            XCTAssertEqual(coding.field, upgrade.field)
            XCTAssertEqual(coding.startYear, upgrade.startYear)
            XCTAssertEqual(coding.endYear, upgrade.endYear)
            XCTAssertEqual(coding.activities, upgrade.activities)
            XCTAssertEqual(coding.accomplishments, upgrade.accomplishments)
        })
    }

    func testDeleteWithInvalideduID() throws {
        try app.test(.DELETE, path + "/1", headers: app.login().headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        try app.test(.DELETE, path + "/" + app.requestEducation(.generate()).id.uuidString, headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

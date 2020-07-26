import XCTVapor
@testable import App

class EduExpCollectionTests: XCAppCase {

    let path = "exp/edu"

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
        XCTAssertNoThrow(try assertCreateEduExperiance(app))
    }

    func testQueryWithInvalidEduID() {
        XCTAssertNoThrow(try assertCreateEduExperiance(app))
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
    }

    func testQueryWithEduID() throws {
        let exp = try assertCreateEduExperiance(app)

        try app.test(.GET, path + "/" + exp.id!.uuidString, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(EducationalExp.Coding.self)
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
        let headers = try registUserAndLoggedIn(app)
        let exp = try assertCreateEduExperiance(app, headers: headers)
        let upgrade = EducationalExp.Coding.init(
            school: "ABC",
            degree: "PhD",
            field: "xxx",
            startYear: "2010",
            activities: ["xxxxx"],
            accomplishments: ["xxxxxxx"]
        )
        try app.test(.PUT, path + "/" + exp.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(EducationalExp.Coding.self)

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
        let headers = try registUserAndLoggedIn(app)
        try assertCreateEduExperiance(app, headers: headers)
        try app.test(.DELETE, path + "/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)

        let exp = try assertCreateEduExperiance(app, headers: headers)

        try app.test(.DELETE, path + "/" + exp.id!.uuidString, headers: headers, afterResponse: assertHttpOk)
    }
}

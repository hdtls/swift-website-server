import XCTVapor
@testable import App

class SkillCollectionTests: XCAppCase {

    let path = "skills"

    func testAuthorizeRequire() throws {
        try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        try assertCreateSkill(app)
    }

    func testQuery() throws {
        let saved = try assertCreateSkill(app)

        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
            .test(.GET, path + "/\(saved.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.Coding.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.profesional, saved.profesional)
            XCTAssertEqual(coding.workflow, saved.workflow)
        })
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)
        let upgrade = Skill.Coding.init(profesional: nil, workflow: ["xxx", "xxxx"])

        let saved = try assertCreateSkill(app, headers: headers)
        
        try app.test(.PUT, path + "/1", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: assertHttpNotFound)
        .test(.PUT, path + "/\(saved.id!)", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.Coding.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertNil(coding.profesional)
            XCTAssertEqual(coding.workflow, upgrade.workflow)
        })
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)

        let saved = try assertCreateSkill(app, headers: headers)

        try app.test(.DELETE, path + "/1", headers: headers, afterResponse: assertHttpNotFound)
            .test(.DELETE, path + "/\(saved.id!)", headers: headers, afterResponse: assertHttpOk)
    }
}

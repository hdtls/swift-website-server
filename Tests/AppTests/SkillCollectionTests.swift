import XCTVapor
@testable import App

class SkillCollectionTests: XCTestCase {

    let path = Skill.schema
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
    
    func testAuthorizeRequire() throws {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
                .test(.GET, path + "/invalid", afterResponse: assertHttpUnprocessableEntity)
                .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
                .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() throws {
        app.requestSkill(.generate())
    }

    func testCreateWithoutWorkflow() throws {
        var expected = Skill.DTO.generate()
        expected.workflow = nil
        app.requestSkill(expected)
    }

    func testCreateWithInvalidDataType() throws {
        let json = ["id": "0", "professional" : ""]
        try app.test(.POST, path, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
        })
    }

    func testQuery() throws {
        let saved = app.requestSkill()

        try app.test(.GET, path + "/\(saved.id)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.DTO.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.professional, saved.professional)
            XCTAssertEqual(coding.workflow, saved.workflow)
        })
    }

    func testQueryWithInvalidID() throws {
        try app.test(.GET, path + "/invalid", afterResponse: assertHttpUnprocessableEntity)
    }

    func testUpdate() throws {
        var saved = app.requestSkill()
        saved.professional.append(.random(length: 12))
        
        try app.test(.PUT, path + "/\(saved.id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(saved)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.DTO.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.professional, saved.professional)
            XCTAssertEqual(coding.workflow, saved.workflow)
        })
    }

    func testUpdateWithInvalidID() throws {
        try app.test(.PUT, path + "/invalid", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(Skill.DTO.generate())
        }, afterResponse: assertHttpUnprocessableEntity)
    }

    func testDelete() throws {
        try app.test(.DELETE, path + "/\(app.requestSkill(.generate()).id)", headers: app.login().headers, afterResponse: assertHttpOk)
    }

    func testDeleteWithInvalidID() throws {
        try app.test(.DELETE, path + "/invalid", headers: app.login().headers, afterResponse: assertHttpUnprocessableEntity)
    }
}

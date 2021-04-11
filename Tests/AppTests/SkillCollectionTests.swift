import XCTVapor
@testable import App

@discardableResult
func assertCreateSkill(
    _ app: Application,
    headers: HTTPHeaders? = authorized
) throws -> Skill.SerializedObject {
    let skill = ["professional": ["xxx"], "workflow": ["xxx"]]

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Skill.SerializedObject!

    try app.test(.POST, "skills", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(skill)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Skill.SerializedObject.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.professional, skill["professional"])
        XCTAssertEqual(coding.workflow, skill["workflow"])
    })

    return coding
}


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
                .test(.GET, path + "/1", afterResponse: assertHttpNotFound)
                .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
                .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreate() throws {
        try assertCreateSkill(app)
    }

    func testCreateWithoutProfessional() throws {
        let json = ["workflow": ["xxx"]]
        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value required for key 'professional'")
        })
    }

    func testCreateWithoutWorkflow() throws {
        let skill = ["professional": ["xxx"]]
        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(skill)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Skill.SerializedObject.self)

            XCTAssertNotNil(coding.id)
            XCTAssertEqual(coding.professional, skill["professional"])
            XCTAssertEqual(coding.workflow, skill["workflow"])
        })
    }

    func testCreateWithInvalidDataType() throws {
        let json = ["professional" : ""]
        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, path, headers: headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value of type 'Array<Any>' required for key 'professional'")
        })
    }

    func testQuery() throws {
        let saved = try assertCreateSkill(app)

        try app.test(.GET, path + "/\(saved.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.SerializedObject.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.professional, saved.professional)
            XCTAssertEqual(coding.workflow, saved.workflow)
        })
    }

    func testQueryWithNonExistentID() throws {
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)
        let upgrade = ["professional": [], "workflow": ["xxx", "xxxx"]]

        let saved = try assertCreateSkill(app, headers: headers)
        
        try app.test(.PUT, path + "/\(saved.id!)", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.SerializedObject.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.professional, [])
            XCTAssertEqual(coding.workflow, upgrade["workflow"])
        })
    }

    func testUpdateWithNoExistentID() throws {
        let headers = try registUserAndLoggedIn(app)

        let upgrade: [String : [String]] = ["professional" : []]

        try app.test(.PUT, path + "/1", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)

        let saved = try assertCreateSkill(app, headers: headers)

        try app.test(.DELETE, path + "/\(saved.id!)", headers: headers, afterResponse: assertHttpOk)
    }

    func testDeleteWithNonExistentID() throws {
        let headers = try registUserAndLoggedIn(app)

        try app.test(.DELETE, path + "/1", headers: headers, afterResponse: assertHttpNotFound)
    }
}

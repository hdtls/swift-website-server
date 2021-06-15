import XCTVapor
@testable import App

class ProjCollectionTests: XCTestCase {
    let path = "projects"
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
        let uuid = UUID.init().uuidString

        try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
    }

    func _testProjCreation(with headers: HTTPHeaders, without key: String) throws {

        var json = [
            "id": "\(UUID())",
            "name": "",
            "summary" : "",
            "kind" : "app",
            "visibility" : "public",
            "startDate" : "",
            "endDate" : ""
        ]

        json.removeValue(forKey: key)

        try app.test(.POST, "projects", headers: headers, beforeRequest: {
            try $0.content.encode(json)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value required for key '\(key)'")
        })
    }

    func testInvalidCreate() throws {
        try _testProjCreation(with: app.login().headers, without: "name")

        try _testProjCreation(with: app.login().headers, without: "summary")

        try _testProjCreation(with: app.login().headers, without: "kind")

        try _testProjCreation(with: app.login().headers, without: "visibility")

        try _testProjCreation(with: app.login().headers, without: "startDate")

        try _testProjCreation(with: app.login().headers, without: "endDate")
    }

    func testCreate() throws {
        app.requestProject(.generate())
    }

    func testQueryWithInvalidWorkID() throws {
        try app.test(.GET, path + "/1", afterResponse: assertHttpUnprocessableEntity)
    }

    func testQueryWithWorkID() throws {
        let proj = app.requestProject()

        try app.test(.GET, path + "/\(proj.id.uuidString)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Project.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertEqual(coding.name, proj.name)
            XCTAssertEqual(coding.note, proj.note)
            XCTAssertEqual(coding.genres, proj.genres)
            XCTAssertEqual(coding.summary, proj.summary)
            XCTAssertEqual(coding.artworkUrl, proj.artworkUrl)
            XCTAssertEqual(coding.backgroundImageUrl, proj.backgroundImageUrl)
            XCTAssertEqual(coding.promoImageUrl, proj.promoImageUrl)
            XCTAssertEqual(coding.screenshotUrls, proj.screenshotUrls)
            XCTAssertEqual(coding.padScreenshotUrls, proj.padScreenshotUrls)
            XCTAssertEqual(coding.kind, proj.kind)
            XCTAssertEqual(coding.visibility, proj.visibility)
            XCTAssertEqual(coding.trackViewUrl, proj.trackViewUrl)
            XCTAssertEqual(coding.trackId, proj.trackId)
            XCTAssertEqual(coding.startDate, proj.startDate)
            XCTAssertEqual(coding.endDate, proj.endDate)
            XCTAssertNotNil(coding.userId)
        })
    }

    func testUpdate() throws {
        let proj = app.requestProject()
        let expected = Project.DTO.generate()
        
        try app.test(.PUT, path + "/" + proj.id.uuidString, headers: app.login().headers, beforeRequest: {
            try $0.content.encode(expected)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Project.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.name, expected.name)
            XCTAssertEqual(coding.note, expected.note)
            XCTAssertEqual(coding.genres, expected.genres)
            XCTAssertEqual(coding.summary, expected.summary)
            XCTAssertEqual(coding.artworkUrl, expected.artworkUrl)
            XCTAssertEqual(coding.backgroundImageUrl, expected.backgroundImageUrl)
            XCTAssertEqual(coding.promoImageUrl, expected.promoImageUrl)
            XCTAssertEqual(coding.screenshotUrls, expected.screenshotUrls)
            XCTAssertEqual(coding.padScreenshotUrls, expected.padScreenshotUrls)
            XCTAssertEqual(coding.kind, expected.kind)
            XCTAssertEqual(coding.visibility, expected.visibility)
            XCTAssertEqual(coding.trackViewUrl, expected.trackViewUrl)
            XCTAssertEqual(coding.trackId, expected.trackId)
            XCTAssertEqual(coding.startDate, expected.startDate)
            XCTAssertEqual(coding.endDate, expected.endDate)
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        try app.test(.DELETE, path + "/1", headers: app.login().headers, afterResponse: assertHttpUnprocessableEntity)
    }

    func testDelete() throws {
        try app.test(.DELETE, path + "/" + app.requestProject(.generate()).id.uuidString, headers: app.login().headers, afterResponse: assertHttpOk)
    }
}

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
        let headers = try registUserAndLoggedIn(app)

        try _testProjCreation(with: headers, without: "name")

        try _testProjCreation(with: headers, without: "summary")

        try _testProjCreation(with: headers, without: "kind")

        try _testProjCreation(with: headers, without: "visibility")

        try _testProjCreation(with: headers, without: "startDate")

        try _testProjCreation(with: headers, without: "endDate")
    }

    func testCreate() throws {
        try assertCreateProj(app)
    }

    func testQueryWithInvalidWorkID() throws {
        try assertCreateProj(app)
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithWorkID() throws {
        let proj = try assertCreateProj(app)

        try app.test(.GET, path + "/\(proj.id!.uuidString)", afterResponse: {
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
        let headers = try registUserAndLoggedIn(app)

        let proj = try assertCreateProj(app, headers: headers)

        try app.test(.PUT, path + "/" + proj.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(
                Project.Coding.init(
                    name: proj.name,
                    genres: proj.genres,
                    summary: proj.summary,
                    kind: .app,
                    visibility: .public,
                    startDate: proj.startDate,
                    endDate: "2020-06-29"
                )
            )
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Project.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
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
            XCTAssertEqual(coding.endDate, "2020-06-29")
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        let headers = try registUserAndLoggedIn(app)
        try assertCreateProj(app, headers: headers)

        try app.test(.DELETE, path + "/" + "1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)
        let proj = try assertCreateProj(app, headers: headers)
        try app.test(.DELETE, path + "/" + proj.id!.uuidString, headers: headers, afterResponse: assertHttpOk)
    }
}

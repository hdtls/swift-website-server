import XCTVapor
@testable import App

class ProjCollectionTests: XCTestCase {
    let app = Application.init(.testing)
    let path = "projects"

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        let uuid = UUID.init().uuidString

        try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path, afterResponse: assertHttpNotFound)
            .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        defer { app.shutdown() }
        try assertCreateProj(app)
    }

    func testQueryWithInvalidWorkID() throws {
        defer { app.shutdown() }

        try assertCreateProj(app)
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithWorkID() throws {
        defer { app.shutdown() }

        let proj = try assertCreateProj(app)

        try app.test(.GET, path + "/\(proj.id!.uuidString)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(Project.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.name, proj.name)
            XCTAssertEqual(coding.categories, proj.categories)
            XCTAssertEqual(coding.summary, proj.summary)
            XCTAssertEqual(coding.startDate, proj.startDate)
            XCTAssertEqual(coding.endDate, proj.endDate)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let proj = try assertCreateProj(app, headers: headers)

        try app.test(.PUT, path + "/" + proj.id!.uuidString, headers: headers, beforeRequest: {
            try $0.content.encode(
                Project.Coding.init(
                    name: proj.name,
                    categories: proj.categories,
                    summary: proj.summary,
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
            XCTAssertEqual(coding.categories, proj.categories)
            XCTAssertEqual(coding.summary, proj.summary)
            XCTAssertEqual(coding.startDate, proj.startDate)
            XCTAssertEqual(coding.endDate, "2020-06-29")
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        try assertCreateProj(app, headers: headers)

        try app.test(.DELETE, path + "/" + "1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        let proj = try assertCreateProj(app, headers: headers)
        try app.test(.DELETE, path + "/" + proj.id!.uuidString, headers: headers, afterResponse: assertHttpOk)
    }
}

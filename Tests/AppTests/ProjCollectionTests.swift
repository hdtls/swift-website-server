import XCTVapor
@testable import App

class ProjCollectionTests: XCAppCase {
    let path = "projects"

    func testAuthorizeRequire() throws {
        let uuid = UUID.init().uuidString

        try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.POST, path + "/\(uuid)/artwork", afterResponse: assertHttpUnauthorized)
            .test(.POST, path + "/\(uuid)/screenshots", afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + uuid, afterResponse: assertHttpUnauthorized)
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
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.name, proj.name)
            XCTAssertEqual(coding.genres, proj.genres)
            XCTAssertEqual(coding.summary, proj.summary)
            XCTAssertEqual(coding.startDate, proj.startDate)
            XCTAssertEqual(coding.endDate, proj.endDate)
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
            XCTAssertEqual(coding.genres, proj.genres)
            XCTAssertEqual(coding.summary, proj.summary)
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

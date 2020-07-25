import XCTVapor
@testable import App

class SocialNetworkingSereviceCollectionTests: XCTestCase {

    let app = Application.init(.testing)
    let path = "social/services"

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testCreate() throws {
        defer { app.shutdown() }
        try assertCreateSocialNetworkingService(app)
    }

    func testQueryWithInvalidID() throws {
        defer { app.shutdown() }
        try assertCreateSocialNetworkingService(app)
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithServiceID() throws {
        defer { app.shutdown() }

        let service = try assertCreateSocialNetworkingService(app)

        try app.test(.GET, path + "/" + service.id!.uuidString, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
            XCTAssertEqual(coding.id, service.id)
            XCTAssertEqual(coding.type, service.type)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let service = try assertCreateSocialNetworkingService(app)

        let copy = SocialNetworkingService.Coding.init(type: .facebook)

        try app.test(.PUT, path + "/" + service.id!.uuidString, beforeRequest: {
            try $0.content.encode(copy)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
            XCTAssertEqual(coding.id, service.id)
            XCTAssertEqual(coding.type, copy.type)
        })
    }

    func testDeleteWithInvalidServiceID() throws {
        defer { app.shutdown() }

        try assertCreateSocialNetworkingService(app)

        try app.test(.DELETE, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let service = try assertCreateSocialNetworkingService(app)

        try app.test(.DELETE, path + "/" + service.id!.uuidString, afterResponse: assertHttpOk)
    }
}

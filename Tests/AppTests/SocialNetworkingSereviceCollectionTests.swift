import XCTVapor
@testable import App

class SocialNetworkingSereviceCollectionTests: XCAppCase {

    let path = "social/services"

    func testCreate() throws {
        try assertCreateSocialNetworkingService(app)
    }

    func testQueryWithInvalidID() throws {
        try assertCreateSocialNetworkingService(app)
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithServiceID() throws {
        let service = try assertCreateSocialNetworkingService(app)

        try app.test(.GET, path + "/" + service.id!.uuidString, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
            XCTAssertEqual(coding.id, service.id)
            XCTAssertEqual(coding.type, service.type)
        })
    }

    func testUpdate() throws {
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
        try assertCreateSocialNetworkingService(app)

        try app.test(.DELETE, path + "/1", afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        let service = try assertCreateSocialNetworkingService(app)

        try app.test(.DELETE, path + "/" + service.id!.uuidString, afterResponse: assertHttpOk)
    }
}

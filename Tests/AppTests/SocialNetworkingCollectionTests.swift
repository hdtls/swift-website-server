import XCTVapor
@testable import App

class SocialNetworkingCollectionTests: XCAppCase {

    let path = "social"

    func testCreate() {
        XCTAssertNoThrow(try assertCreateSocialNetworking(app))
    }

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpNotFound)
            .test(.GET, "social", afterResponse: assertHttpNotFound)
            .test(.PUT, path + "/" + UUID().uuidString, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + UUID().uuidString, afterResponse: assertHttpUnauthorized)
        )
    }

    func testQueryWithInvalidID() {
        XCTAssertNoThrow(try assertCreateSocialNetworking(app))
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound))
    }

    func testQueryWithSocialID() throws {
        let socialNetworking = try assertCreateSocialNetworking(app)

        try app.test(.GET, path + "/\(socialNetworking.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworking.Coding.self)
            XCTAssertEqual(coding, socialNetworking)
        })
    }

    func testUpdate() throws {
        let headers = try registUserAndLoggedIn(app)
        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)
        let upgrade = SocialNetworking.Coding.init(
            url: "https://facebook.com",
            service: socialNetworking.service
        )
        try app.test(.PUT, path + "/\(socialNetworking.id!)", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworking.Coding.self)
            XCTAssertEqual(coding.id, socialNetworking.id)
            XCTAssertEqual(coding.url, upgrade.url)
            XCTAssertEqual(coding.service, upgrade.service)
        })
    }

    func testDelete() throws {
        let headers = try registUserAndLoggedIn(app)
        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)

        try app.test(.DELETE, path + "/\(socialNetworking.id!)", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        }).test(.DELETE, path + "/\(socialNetworking.id!)", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .notFound)
        }).test(.DELETE, path + "/1", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .notFound)
        })
    }
}

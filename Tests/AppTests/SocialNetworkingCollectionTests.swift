import XCTVapor
@testable import App

class SocialNetworkingCollectionTests: XCTestCase {

    let path = SocialNetworking.schema
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

    func testCreate() {
        var expected = SocialNetworking.DTO.generate()
        expected.serviceId = app.requestSocialNetworkingService(.generate()).id
        app.requestSocialNetworking(expected)
    }

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpNotFound)
                .test(.GET, path, afterResponse: assertHttpOk)
            .test(.PUT, path + "/" + UUID().uuidString, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/" + UUID().uuidString, afterResponse: assertHttpUnauthorized)
        )
    }

    func testQueryWithInvalidID() {
        XCTAssertNoThrow(try app.test(.GET, path + "/1", afterResponse: assertHttpUnprocessableEntity))
    }

    func testQueryWithSocialID() throws {
        let socialNetworking = app.requestSocialNetworking()

        try app.test(.GET, path + "/\(socialNetworking.id)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworking.Coding.self)
            XCTAssertEqual(coding, socialNetworking)
        })
    }

    func testUpdate() throws {
        var socialNetworking = app.requestSocialNetworking()
        socialNetworking.url = .random(length: 16)
        
        try app.test(.PUT, path + "/\(socialNetworking.id)", headers: app.login().headers, beforeRequest: {
            try $0.content.encode(socialNetworking)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworking.Coding.self)
            XCTAssertEqual(coding.id, socialNetworking.id)
            XCTAssertEqual(coding.url, socialNetworking.url)
            XCTAssertEqual(coding.service, socialNetworking.service)
        })
    }

    func testDelete() throws {
        var expected = SocialNetworking.DTO.generate()
        expected.serviceId = app.requestSocialNetworkingService(.generate()).id
        let socialNetworking = app.requestSocialNetworking(expected)

        try app.test(.DELETE, path + "/\(socialNetworking.id)", headers: app.login().headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        }).test(.DELETE, path + "/\(socialNetworking.id)", headers: app.login().headers, afterResponse: {
            XCTAssertEqual($0.status, .notFound)
        }).test(.DELETE, path + "/1", headers: app.login().headers, afterResponse: assertHttpUnprocessableEntity)
    }
}

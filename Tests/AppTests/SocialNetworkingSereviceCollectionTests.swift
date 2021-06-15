import XCTVapor
@testable import App

class SocialNetworkingSereviceCollectionTests: XCTestCase {

    let path = "\(SocialNetworking.schema)/services"
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

    func testCreate() throws {
        app.requestSocialNetworkingService(.generate())
    }

    func testQueryWithInvalidID() throws {
        try app.test(.GET, path + "/invalid", afterResponse: assertHttpUnprocessableEntity)
    }

    func testQueryWithServiceID() throws {
        let service = app.requestSocialNetworkingService()

        try app.test(.GET, path + "/\(service.id)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
            XCTAssertEqual(coding.id, service.id)
            XCTAssertEqual(coding.type, service.type)
        })
    }

    func testUpdate() throws {
        let service = app.requestSocialNetworkingService(.generate())
                
        var copy = SocialNetworkingService.Coding.init()
        copy.type = .facebook

        try app.test(.PUT, path + "/\(service.id)", beforeRequest: {
            try $0.content.encode(copy)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
            XCTAssertEqual(coding.id, service.id)
            XCTAssertEqual(coding.type, copy.type)
        })
    }

    func testDeleteWithInvalidServiceID() throws {
        try app.test(.DELETE, path + "/invalid", afterResponse: assertHttpUnprocessableEntity)
    }

    func testDelete() throws {
        try app.test(.DELETE, path + "/\(app.requestSocialNetworkingService(.generate()).id)", afterResponse: assertHttpOk)
    }
}

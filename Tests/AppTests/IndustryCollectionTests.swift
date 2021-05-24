import XCTVapor
@testable import App

class IndustryCollectionTests: XCTestCase {

    let path = Industry.schema
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
        app.requestIndustry(.generate())
    }

    func testCreateWithConflictIndustry() throws {
        var industry = app.requestIndustry()
        industry.id = nil
        
        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(industry)
        }, afterResponse: {
            print($0.status, $0)
            XCTAssertEqual($0.status, .unprocessableEntity)
        })
    }
    
    func testQueryWithInvalidID() throws {
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithID() throws {
        let industry = app.requestIndustry()
        
        try app.test(.GET, path + "/\(industry.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Industry.Coding.self)
            XCTAssertEqual(coding, industry)
        })
    }
    
    func testQueryAll() throws {
//        try assertCreateIndustry(app)
//
//        try app.test(.GET, path, afterResponse: {
//            XCTAssertEqual($0.status, .ok)
//            let coding = try $0.content.decode([Industry.Coding].self)
//            XCTAssertEqual(coding.count, 1)
//        })
    }
    
    func testUpdate() throws {
        var expected = app.requestIndustry(.generate())
        expected.title = .random(length: 7)
        
        try app.test(.PUT, path + "/\(expected.id!)", beforeRequest: {
            try $0.content.encode(expected)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Industry.SerializedObject.self)
            XCTAssertNotNil(coding.id)
            XCTAssertEqual(coding.title, expected.title)
        })
    }
    
    func testDelete() throws {
        let industry = app.requestIndustry(.generate())
        
        try app.test(.DELETE, path + "/\(industry.id!)", afterResponse: assertHttpOk)
            .test(.DELETE, path + "/1", afterResponse: assertHttpNotFound)
    }
}

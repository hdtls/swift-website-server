import XCTVapor
@testable import App

class IndustryCollectionTests: XCTestCase {
    
    let app = Application.init(.testing)
    let path = Industry.schema

    override func setUpWithError() throws {
        try bootstrap(app)
        
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    
    func testCreate() {
        defer { app.shutdown() }
        
        XCTAssertNoThrow(try assertCreateIndustry(app))
    }

    func testCreateWithConflictIndustry() throws {
        defer { app.shutdown() }

        let industry = try assertCreateIndustry(app)

        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(industry)
        }, afterResponse: {
            XCTAssertEqual($0.status, .conflict)
        })
    }
    
    func testQueryWithInvalidID() throws {
        defer { app.shutdown() }
        
        try assertCreateIndustry(app)
        
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithID() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.GET, path + "/\(industry.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Industry.Coding.self)
            XCTAssertEqual(coding, industry)
        })
    }
    
    func testQueryAll() throws {
        defer { app.shutdown() }
        
        try assertCreateIndustry(app)
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([Industry.Coding].self)
            XCTAssertEqual(coding.count, 1)
        })
    }
    
    func testUpdate() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.PUT, path + "/\(industry.id!)", beforeRequest: {
            try $0.content.encode(Industry.Coding.init(title: "12345"))
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Industry.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertEqual(coding.title, "12345")
        })
    }
    
    func testDelete() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.DELETE, path + "/\(industry.id!)", afterResponse: assertHttpOk)
            .test(.DELETE, path + "/1", afterResponse: assertHttpNotFound)
    }
}

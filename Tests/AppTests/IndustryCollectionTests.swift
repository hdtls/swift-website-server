import XCTVapor
@testable import App

class IndustryCollectionTests: XCAppCase {

    let path = Industry.schema

    func testCreate() {
        XCTAssertNoThrow(try assertCreateIndustry(app))
    }

    func testCreateWithConflictIndustry() throws {
        let industry = try assertCreateIndustry(app)

        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(industry)
        }, afterResponse: {
            XCTAssertEqual($0.status, .conflict)
        })
    }
    
    func testQueryWithInvalidID() throws {
        try assertCreateIndustry(app)
        
        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithID() throws {
        let industry = try assertCreateIndustry(app)
        
        try app.test(.GET, path + "/\(industry.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Industry.Coding.self)
            XCTAssertEqual(coding, industry)
        })
    }
    
    func testQueryAll() throws {
        try assertCreateIndustry(app)
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([Industry.Coding].self)
            XCTAssertEqual(coding.count, 1)
        })
    }
    
    func testUpdate() throws {
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
        let industry = try assertCreateIndustry(app)
        
        try app.test(.DELETE, path + "/\(industry.id!)", afterResponse: assertHttpOk)
            .test(.DELETE, path + "/1", afterResponse: assertHttpNotFound)
    }
}

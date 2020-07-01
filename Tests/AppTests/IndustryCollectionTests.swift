//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Eli Zhang, and the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTVapor
@testable import App

class IndustryCollectionTests: XCTestCase {
    
    let app = Application.init(.testing)
    
    override func setUpWithError() throws {
        try bootstrap(app)
        
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    
    func testCreate() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.POST, Industry.schema, beforeRequest: {
            try $0.content.encode(industry)
        }, afterResponse: {
            XCTAssertEqual($0.status, .conflict)
        })
    }
    
    func testQueryWithInvalidID() throws {
        defer { app.shutdown() }
        
        _ = try assertCreateIndustry(app)
        
        try app.test(.GET, Industry.schema + "/1", afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithID() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.GET, Industry.schema + "/\(industry.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            
            let coding = try $0.content.decode(Industry.Coding.self)
            XCTAssertEqual(coding, industry)
        })
    }
    
    func testQueryAll() throws {
        defer { app.shutdown() }
        
        try assertCreateIndustry(app)
        
        try app.test(.GET, Industry.schema, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([Industry.Coding].self)
            XCTAssertEqual(coding.count, 1)
        })
    }
    
    func testUpdate() throws {
        defer { app.shutdown() }
        
        let industry = try assertCreateIndustry(app)
        
        try app.test(.PUT, Industry.schema + "/\(industry.id!)", beforeRequest: {
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
        
        try app.test(.DELETE, Industry.schema + "/\(industry.id!)", afterResponse: assertHttpOk)
            .test(.DELETE, Industry.schema + "/1", afterResponse: assertHttpNotFound)
    }
}

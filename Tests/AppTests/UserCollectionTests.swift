//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Netbot Ltd. and the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTVapor
@testable import App

class UserCollectionTests: XCTestCase {
    
    func testUserCreation() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try bootstrap(app)
        
        try app.test(.POST, "users", beforeRequest: {
            try $0.content.encode(User.Registration.init(username: "website", password: "website"))
        }, afterResponse: {
        
        })
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

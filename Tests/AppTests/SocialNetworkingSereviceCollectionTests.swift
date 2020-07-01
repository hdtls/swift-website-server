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

let socialNetworkingService = SocialNetworkingService.Coding.init(type: .twitter, html: "<div></div>")

class SocialNetworkingSereviceCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testCreate() throws {
        defer { app.shutdown() }
        try assertCreateNetworkingService(app)
    }

    func testQueryWithInvalidID() throws {
        defer { app.shutdown() }

        try app.test(.GET, "social/services/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithServiceID() throws {
        defer { app.shutdown() }

        try assertCreateNetworkingService(app, completion: { [weak app] in

            try app?.test(.GET, "social/services/" + $0.uuidString, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.type)
                XCTAssertEqual(coding.html, socialNetworkingService.html)
                XCTAssertNil(coding.imageUrl)
            })
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        try app.test(.GET, "social/services", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([SocialNetworkingService.Coding].self)
            XCTAssertEqual(coding.count, 0)
        })

        try assertCreateNetworkingService(app, completion: { [weak app] serviceID in
            try app?.test(.GET, "social/services", afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode([SocialNetworkingService.Coding].self)
                XCTAssertEqual(coding.count, 1)
                XCTAssertEqual(coding.first!.id, serviceID)
            })
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        try assertCreateNetworkingService(app, completion: { [weak app] serviceID in

            let copy = SocialNetworkingService.Coding.init(type: .facebook, imageUrl: "https://profile.com/1", html: "<div><svg></svg></div>")

            try app?.test(.PUT, "social/services/" + serviceID.uuidString, beforeRequest: {
                try $0.content.encode(copy)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
                XCTAssertEqual(coding.id, serviceID)
                XCTAssertEqual(coding.type, copy.type)
                XCTAssertEqual(coding.imageUrl, copy.imageUrl)
                XCTAssertEqual(coding.html, copy.html)
            })
        })
    }

    func testDeleteWithInvalidServiceID() throws {
        defer { app.shutdown() }

        try assertCreateNetworkingService(app, completion: { [weak app] _ in

            try app?.test(.DELETE, "social/services/1", afterResponse: assertHttpNotFound)
        })
    }

    func testDelete() throws {
        defer { app.shutdown() }

        try assertCreateNetworkingService(app, completion: { [weak app] in

            try app?.test(.DELETE, "social/services/" + $0.uuidString, afterResponse: assertHttpOk)
        })
    }
}

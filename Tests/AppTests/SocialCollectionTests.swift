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


func assertCreateSocial(_ app: Application, completion: ((HTTPHeaders, Social.Coding) throws -> Void)? = nil) throws {
    try assertCreateNetworkingService(app, completion: { [unowned app] serviceID in
        try registUserAndLoggedIn(app, completion: { headers in
            try app.test(.POST, "social", headers: headers, beforeRequest: {
                try $0.content.encode(Social.Coding.init(url: "https://twitter.com/uid", networkingServiceId: serviceID))
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(Social.Coding.self)

                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.url, "https://twitter.com/uid")
                XCTAssertNotNil(coding.networkingService)
                XCTAssertEqual(coding.networkingService?.id, serviceID)

                try completion?(headers, coding)
            })
        })
    })
}

class SocialCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testCreate() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app)
    }

    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        func assertUnauthorized(_ response: XCTHTTPResponse) throws {
            XCTAssertEqual(response.status, .unauthorized)
        }

        try app.test(.POST, "social", afterResponse: assertUnauthorized(_:))
        .test(.GET, "social/" + UUID().uuidString, afterResponse: assertUnauthorized(_:))
        .test(.GET, "social", afterResponse: assertUnauthorized(_:))
        .test(.PUT, "social/" + UUID().uuidString, afterResponse: assertUnauthorized(_:))
        .test(.DELETE, "social/" + UUID().uuidString, afterResponse: assertUnauthorized(_:))
    }

    func testQueryWithInvalidID() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app, completion: { [unowned app] headers, social in
            try app.test(.GET, "social/1", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }

    func testQueryWithSocialID() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app, completion: { [unowned app] headers, social in
            try app.test(.GET, "social/\(social.id!)", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(Social.Coding.self)
                XCTAssertEqual(coding, social)
            })
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app, completion: { [unowned app] headers, social in
            try app.test(.GET, "social", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode([Social.Coding].self)
                XCTAssertEqual(coding.count, 1)
                XCTAssertEqual(coding.first!, social)
            })
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app, completion: { [unowned app] headers, social in
            try app.test(.PUT, "social/\(social.id!)", headers: headers, beforeRequest: {
                try $0.content.encode(
                    Social.Coding.init(
                        url: "https://facebook.com",
                        networkingServiceId: social.id
                    )
                )
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(Social.Coding.self)
                XCTAssertEqual(coding.id, social.id)
                XCTAssertEqual(coding.url, "https://facebook.com")
                XCTAssertEqual(coding.networkingService, social.networkingService)
            })
        })
    }

    func testDelete() throws {
        defer { app.shutdown() }

        try assertCreateSocial(app, completion: { [unowned app] headers, social in
            try app.test(.DELETE, "social/\(social.id!)", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            }).test(.DELETE, "social/\(social.id!)", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            }).test(.DELETE, "social/1", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }
}

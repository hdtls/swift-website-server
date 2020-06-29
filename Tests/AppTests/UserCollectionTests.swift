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

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    
    func testCreateWithInvalidUsername() throws {
        defer { app.shutdown() }

        try app.test(.POST, "users", beforeRequest: {
            try $0.content.encode(User.Creation.init(username: "", password: "111111"))
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
        })
    }

    func testCreateWithInvalidPassword() throws {
        defer { app.shutdown() }

        try app.test(.POST, "users", beforeRequest: {
            try $0.content.encode(User.Creation.init(username: "test", password: "111"))
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
        })
    }

    func testCreateWithConflictUsername() throws {
        defer { app.shutdown() }

        let username = "test"
        let password = "111111"

        try registUserAndLoggedIn(app)

        try app.test(.POST, "users", beforeRequest: {
            try $0.content.encode(User.Creation.init(username: username, password: password))
        }, afterResponse: {
            XCTAssertEqual($0.status, .conflict)
        })
    }

    func testCreate() throws {
        defer { app.shutdown() }
        try registUserAndLoggedIn(app)
    }

    func testQueryWithInvalidUserID() throws {
        defer { app.shutdown() }

        try app.test(.GET, "users/didnotcreated", afterResponse: {
            XCTAssertEqual($0.status, .notFound)
        })
    }

    func testQueryWithUserID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        try app.test(.GET, "users/test", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))

            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, "test")
            XCTAssertNil(user.name)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.profileBackgroundColor)
            XCTAssertNil(user.profileBackgroundImageUrl)
            XCTAssertNil(user.profileBackgroundTile)
            XCTAssertNil(user.profileImageUrl)
            XCTAssertNil(user.profileBannerUrl)
            XCTAssertNil(user.profileLinkColor)
            XCTAssertNil(user.profileTextColor)
            XCTAssertNil(user.webLinks)
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.jobExps)
        })
    }

    func testQueryWithUserIDAndQueryParameters() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        let query = "?include_web_links=true&include_edu_exp=true&include_job_exp=true"
        try app.test(.GET, "users/test" + query, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))

            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, "test")
            XCTAssertNil(user.name)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.profileBackgroundColor)
            XCTAssertNil(user.profileBackgroundImageUrl)
            XCTAssertNil(user.profileBackgroundTile)
            XCTAssertNil(user.profileImageUrl)
            XCTAssertNil(user.profileBannerUrl)
            XCTAssertNil(user.profileLinkColor)
            XCTAssertNil(user.profileTextColor)
            XCTAssertEqual(user.webLinks, [])
            XCTAssertEqual(user.eduExps, [])
            XCTAssertEqual(user.jobExps, [])
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        try app.test(.GET, "users", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 0)
        })

        try registUserAndLoggedIn(app)

        try app.test(.GET, "users", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 1)
        })
    }

    func testUpdateWithUnauthorized() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        try app.test(.PUT, "users/test", beforeRequest: {
            try $0.content.encode(
                User.Coding.init(
                    screenName: "Jack",
                    phone: "+1 888888888",
                    emailAddress: "test@test.com",
                    aboutMe: "HELLO WORLD !!!"
                )
            )
        }, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))
            try app?.test(.PUT, "users/test", headers: headers, beforeRequest: {

                try $0.content.encode(
                    User.Coding.init(
                        screenName: "Jack",
                        phone: "+1 888888888",
                        emailAddress: "test@test.com",
                        aboutMe: "HELLO WORLD !!!"
                    )
                )
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                XCTAssertNoThrow(try $0.content.decode(User.Coding.self))

                let user = try! $0.content.decode(User.Coding.self)
                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, "test")
                XCTAssertNil(user.name)
                XCTAssertEqual(user.screenName, "Jack")
                XCTAssertEqual(user.phone, "+1 888888888")
                XCTAssertEqual(user.emailAddress, "test@test.com")
                XCTAssertEqual(user.aboutMe, "HELLO WORLD !!!")
                XCTAssertNil(user.location)
                XCTAssertNil(user.profileBackgroundColor)
                XCTAssertNil(user.profileBackgroundImageUrl)
                XCTAssertNil(user.profileBackgroundTile)
                XCTAssertNil(user.profileImageUrl)
                XCTAssertNil(user.profileBannerUrl)
                XCTAssertNil(user.profileLinkColor)
                XCTAssertNil(user.profileTextColor)
                XCTAssertNil(user.webLinks)
                XCTAssertNil(user.eduExps)
                XCTAssertNil(user.jobExps)
            })
        })
    }
}

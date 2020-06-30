//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Eli Zhang and the website-backend project authors
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
            XCTAssertNil(user.social)
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.jobExps)
        })
    }

    func testQueryWithUserIDAndQueryParameters() throws {
        defer { app.shutdown() }

        var headers: HTTPHeaders?
        try registUserAndLoggedIn(app, completion: { headers = $0 })
        XCTAssertNotNil(headers)

        let query = "?include_social=true&include_edu_exp=true&include_job_exp=true"
        try app.test(.GET, "users/test\(query)", afterResponse: {
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
            XCTAssertEqual(user.social, [])
            XCTAssertEqual(user.eduExps, [])
            XCTAssertEqual(user.jobExps, [])
        })

        var social: Social.Coding?
        try assertCreateSocial(app, headers: headers, completion: { (_, s) in
            social = s
        })
        XCTAssertNotNil(social)

        func assertSuccess(_ response: XCTHTTPResponse) throws {
            XCTAssertEqual(response.status, .ok)
        }

        try app.test(.POST, "exp/jobs", headers: headers!, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: assertSuccess)
        .test(.POST, "exp/edu", headers: headers!, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: assertSuccess)
        .test(.GET, "users/test\(query)", afterResponse: {
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
            XCTAssertNotNil(user.social?.first)
            XCTAssertNotNil(user.eduExps?.first)
            XCTAssertNotNil(user.jobExps?.first)
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

    func testQueryAfterAddChildrens() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            try app?.test(.POST, "exp/jobs", headers: $0, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            }).test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            })
            .test(.GET, "users?include_edu_exp=true&include_job_exp=true", afterResponse: {
                XCTAssertEqual($0.status, .ok)
                XCTAssertNoThrow(try $0.content.decode([User.Coding].self))

                let users = try $0.content.decode([User.Coding].self)
                XCTAssertNotNil(users.first)

                let user = users.first!

                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, "test")
                XCTAssertNil(user.name)
                XCTAssertNil(user.screenName)
                XCTAssertNil(user.phone)
                XCTAssertNil(user.emailAddress)
                XCTAssertNil(user.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertEqual(user.eduExps!.count, 1)
                XCTAssertEqual(user.jobExps!.count, 1)

                let job = user.jobExps!.first!
                XCTAssertNotNil(job.id)
                XCTAssertNotNil(job.userId)
                XCTAssertEqual(job.title, jobExpCoding.title)
                XCTAssertEqual(job.companyName, jobExpCoding.companyName)
                XCTAssertEqual(job.location, jobExpCoding.location)
                XCTAssertEqual(job.startDate, jobExpCoding.startDate)
                XCTAssertEqual(job.endDate, jobExpCoding.endDate)
                XCTAssertEqual(job.industry.count, 0)
                XCTAssertNil(job.headline)
                XCTAssertNil(job.responsibilities)
                

                let edu = user.eduExps!.first!
                XCTAssertNotNil(edu.id)
                XCTAssertNotNil(edu.userId)
                XCTAssertEqual(edu.startAt, eduExpCoding.startAt)
                XCTAssertEqual(edu.endAt, eduExpCoding.endAt)
                XCTAssertEqual(edu.education, eduExpCoding.education)
            })
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

        try registUserAndLoggedIn(app, completion: { [unowned app] in
            try app.test(.PUT, "users/test", headers: $0, beforeRequest: {

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
                XCTAssertNil(user.social)
                XCTAssertNil(user.eduExps)
                XCTAssertNil(user.jobExps)
            })
        })
    }
}

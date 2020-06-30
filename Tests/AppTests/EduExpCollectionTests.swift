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

let eduExpCoding = EduExp.Coding.init(startAt: "2010-09-01", endAt: "2014-06-26", education: "Bachelor Degree")

class EduExpCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    
    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        let uuid = UUID.init().uuidString

        try app.test(.POST, "exp/edu", afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.GET, "exp/edu/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.GET, "exp/edu", afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.PUT, "exp/edu/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.DELETE, "exp/edu/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        })
    }

    func testCreate() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            try app?.test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(EduExp.Coding.self)
                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.startAt, eduExpCoding.startAt)
                XCTAssertEqual(coding.endAt, eduExpCoding.endAt)
                XCTAssertEqual(coding.education, eduExpCoding.education)
            })
        })
    }

    func testQueryWithInvalidEduID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            try app?.test(.GET, "exp/edu/1", headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }

    func testQueryWithEduID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            var eduID: String!

            try app?.test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                let coding = try $0.content.decode(EduExp.Coding.self)
                eduID = coding.id!.uuidString
            }).test(.GET, "exp/edu/" + eduID, headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(EduExp.Coding.self)
                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.startAt, eduExpCoding.startAt)
                XCTAssertEqual(coding.endAt, eduExpCoding.endAt)
                XCTAssertEqual(coding.education, eduExpCoding.education)
            })
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            try app?.test(.GET, "exp/edu", headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode([EduExp.Coding].self)
                XCTAssertEqual(coding.count, 0)
            })
            .test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            })
            .test(.GET, "exp/edu", headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode([EduExp.Coding].self)
                XCTAssertEqual(coding.count, 1)
            })
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let education = "B.S.E"

            var eduID: String!

            try app?.test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(EduExp.Coding.self)
                eduID = coding.id!.uuidString
                XCTAssertEqual(coding.education, eduExpCoding.education)
            })
            .test(.PUT, "exp/edu/" + eduID, headers: $0, beforeRequest: {
                try $0.content.encode(
                    EduExp.Coding.init(
                        startAt: eduExpCoding.startAt,
                        endAt: eduExpCoding.endAt,
                        education: education
                    )
                )
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(EduExp.Coding.self)

                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.education, education)
                XCTAssertEqual(coding.startAt, eduExpCoding.startAt)
                XCTAssertEqual(coding.endAt, eduExpCoding.endAt)
            })
        })
    }

    func testDeleteWithInvalideduID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            try app?.test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }).test(.DELETE, "exp/edu/1", headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }

    func testDelete() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            var eduID: String!

            try app?.test(.POST, "exp/edu", headers: $0, beforeRequest: {
                try $0.content.encode(eduExpCoding)
            }, afterResponse: {
                let coding = try $0.content.decode(EduExp.Coding.self)
                eduID = coding.id!.uuidString
            }).test(.DELETE, "exp/edu/" + eduID, headers: $0, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            })
        })
    }
}

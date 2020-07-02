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

let eduExpCoding = EducationalExp.Coding.init(
    school: "BALABALA",
    degree: "PhD",
    field: "xxx",
    startYear: "2010",
    activities: ["xxxxx"]
)

//init(startAt: "2010-09-01", endAt: "2014-06-26", education: "Bachelor Degree")

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

        try app.test(.POST, "exp/edu", afterResponse: assertHttpUnauthorized)
            .test(.GET, "exp/edu/" + uuid, afterResponse: assertHttpNotFound)
            .test(.PUT, "exp/edu/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, "exp/edu/" + uuid, afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(EducationalExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.school, eduExpCoding.school)
            XCTAssertEqual(coding.degree, eduExpCoding.degree)
            XCTAssertEqual(coding.field, eduExpCoding.field)
            XCTAssertEqual(coding.startYear, eduExpCoding.startYear)
            XCTAssertNil(coding.endYear)
            XCTAssertEqual(coding.activities, eduExpCoding.activities)
            XCTAssertNil(coding.accomplishments)
        })
    }

    func testQueryWithInvalidEduID() throws {
        defer { app.shutdown() }
        try app.test(.GET, "exp/edu/1", afterResponse: assertHttpNotFound)
    }

    func testQueryWithEduID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        var eduID: String!

        try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: {
            let coding = try $0.content.decode(EducationalExp.Coding.self)
            eduID = coding.id!.uuidString
        }).test(.GET, "exp/edu/" + eduID, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(EducationalExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.school, eduExpCoding.school)
            XCTAssertEqual(coding.degree, eduExpCoding.degree)
            XCTAssertEqual(coding.field, eduExpCoding.field)
            XCTAssertEqual(coding.startYear, eduExpCoding.startYear)
            XCTAssertNil(coding.endYear)
            XCTAssertEqual(coding.activities, eduExpCoding.activities)
            XCTAssertNil(coding.accomplishments)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        var eduID: String!

        try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(EducationalExp.Coding.self)
            eduID = coding.id!.uuidString
        })
        .test(.PUT, "exp/edu/" + eduID, headers: headers, beforeRequest: {
            try $0.content.encode(
                EducationalExp.Coding.init(
                    school: "ABC",
                    degree: "PhD",
                    field: "xxx",
                    startYear: "2010",
                    activities: ["xxxxx"],
                    accomplishments: ["xxxxxxx"]
                )
            )
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(EducationalExp.Coding.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.school, "ABC")
            XCTAssertEqual(coding.degree, "PhD")
            XCTAssertEqual(coding.field, "xxx")
            XCTAssertEqual(coding.startYear, "2010")
            XCTAssertNil(coding.endYear)
            XCTAssertEqual(coding.activities, ["xxxxx"])
            XCTAssertEqual(coding.accomplishments, ["xxxxxxx"])
        })
    }

    func testDeleteWithInvalideduID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        })
        .test(.DELETE, "exp/edu/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        var eduID: String!

        try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: {
            let coding = try $0.content.decode(EducationalExp.Coding.self)
            eduID = coding.id!.uuidString
        }).test(.DELETE, "exp/edu/" + eduID, headers: headers, afterResponse: assertHttpOk)
    }
}

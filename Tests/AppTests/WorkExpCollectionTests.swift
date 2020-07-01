//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTVapor
@testable import App

var workExpCoding = WorkExp.Coding.init(
    title: "iOS Developer",
    companyName: "XXX",
    location: "XXX",
    startDate: "2020-02-20",
    endDate: "-",
    industry: [
        Industry.Coding.init(title: "International Trade & Development")
    ]
)

class WorkExpCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        let uuid = UUID.init().uuidString

        try app.test(.POST, "exp/works", afterResponse: assertHttpUnauthorized)
            .test(.GET, "exp/works", afterResponse: assertHttpUnauthorized)
            .test(.GET, "exp/works/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.PUT, "exp/works/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, "exp/works/" + uuid, afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let industry = try assertCreateIndustry(app, industry: workExpCoding.industry.first)

        try app.test(.POST, "exp/works", headers: headers, beforeRequest: {
            workExpCoding.industry = [industry]
            try $0.content.encode(workExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(WorkExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, workExpCoding.title)
            XCTAssertEqual(coding.companyName, workExpCoding.companyName)
            XCTAssertEqual(coding.location, workExpCoding.location)
            XCTAssertEqual(coding.startDate, workExpCoding.startDate)
            XCTAssertEqual(coding.endDate, workExpCoding.endDate)
            XCTAssertEqual(coding.industry.count, 1)
            XCTAssertNotNil(coding.industry.first!.id)
            XCTAssertEqual(coding.industry.first!.title, industry.title)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testQueryWithInvalidWorkID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.GET, "exp/works/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testQueryWithWorkID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let industry = try assertCreateIndustry(app, industry: workExpCoding.industry.first)

        var workID: WorkExp.IDValue!

        try app.test(.POST, "exp/works", headers: headers, beforeRequest: {
            workExpCoding.industry = [industry]
            try $0.content.encode(workExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(WorkExp.Coding.self)
            XCTAssertNotNil(coding.id)
            workID = coding.id
        })
        .test(.GET, "exp/works/\(workID.uuidString)", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(WorkExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, workExpCoding.title)
            XCTAssertEqual(coding.companyName, workExpCoding.companyName)
            XCTAssertEqual(coding.location, workExpCoding.location)
            XCTAssertEqual(coding.startDate, workExpCoding.startDate)
            XCTAssertEqual(coding.endDate, workExpCoding.endDate)
            XCTAssertEqual(coding.industry.count, 1)
            XCTAssertNotNil(coding.industry.first!.id)
            XCTAssertEqual(coding.industry.first!.title, industry.title)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.GET, "exp/works", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([WorkExp.Coding].self)
            XCTAssertEqual(coding.count, 0)
        })
        .test(.POST, "exp/works", headers: headers, beforeRequest: {
            try $0.content.encode(workExpCoding)
        }, afterResponse: assertHttpOk)
        .test(.GET, "exp/works", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([WorkExp.Coding].self)
            XCTAssertEqual(coding.count, 1)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        var workID: String!

        try app.test(.POST, "exp/works", headers: headers, beforeRequest: {
            try $0.content.encode(workExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(WorkExp.Coding.self)
            workID = coding.id!.uuidString
        })
        .test(.PUT, "exp/works/" + workID, headers: headers, beforeRequest: {
            try $0.content.encode(
                WorkExp.Coding.init(
                    title: workExpCoding.title,
                    companyName: workExpCoding.companyName,
                    location: workExpCoding.location,
                    startDate: workExpCoding.startDate,
                    endDate: "2020-06-29",
                    industry: []
                )
            )
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(WorkExp.Coding.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, workExpCoding.title)
            XCTAssertEqual(coding.companyName, workExpCoding.companyName)
            XCTAssertEqual(coding.location, workExpCoding.location)
            XCTAssertEqual(coding.startDate, workExpCoding.startDate)
            XCTAssertEqual(coding.endDate, "2020-06-29")
            XCTAssertEqual(coding.industry.count, 0)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testDeleteWithInvalidWorkID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, "exp/works", headers: headers, beforeRequest: {
            try $0.content.encode(workExpCoding)
        }).test(.DELETE, "exp/works/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        var workID: String!

        try app.test(.POST, "exp/works", headers: headers, beforeRequest: {
            try $0.content.encode(workExpCoding)
        }, afterResponse: {
            let coding = try $0.content.decode(WorkExp.Coding.self)
            workID = coding.id!.uuidString
        }).test(.DELETE, "exp/works/" + workID, headers: headers, afterResponse: assertHttpOk)
    }
}

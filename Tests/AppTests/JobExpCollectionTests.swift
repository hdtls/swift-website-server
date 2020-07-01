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

var jobExpCoding = JobExp.Coding.init(
    title: "iOS Developer",
    companyName: "XXX",
    location: "XXX",
    startDate: "2020-02-20",
    endDate: "-",
    industry: [
        Industry.Coding.init(title: "International Trade & Development")
    ]
)

class JobExpCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        let uuid = UUID.init().uuidString

        try app.test(.POST, "exp/jobs", afterResponse: assertHttpUnauthorized)
            .test(.GET, "exp/jobs", afterResponse: assertHttpUnauthorized)
            .test(.GET, "exp/jobs/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.PUT, "exp/jobs/" + uuid, afterResponse: assertHttpUnauthorized)
            .test(.DELETE, "exp/jobs/" + uuid, afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let industry = try assertCreateIndustry(app, industry: jobExpCoding.industry.first!)

        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            jobExpCoding.industry = [industry]
            try $0.content.encode(jobExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(JobExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, jobExpCoding.title)
            XCTAssertEqual(coding.companyName, jobExpCoding.companyName)
            XCTAssertEqual(coding.location, jobExpCoding.location)
            XCTAssertEqual(coding.startDate, jobExpCoding.startDate)
            XCTAssertEqual(coding.endDate, jobExpCoding.endDate)
            XCTAssertEqual(coding.industry.count, 1)
            XCTAssertNotNil(coding.industry.first!.id)
            XCTAssertEqual(coding.industry.first!.title, industry.title)
            XCTAssertNil(coding.headline)
            XCTAssertNil(coding.responsibilities)
        })
    }

    func testQueryWithInvalidJobID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.GET, "exp/jobs/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testQueryWithJobID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let industry = try assertCreateIndustry(app, industry: jobExpCoding.industry.first!)

        var jobID: JobExp.IDValue!

        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            jobExpCoding.industry = [industry]
            try $0.content.encode(jobExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(JobExp.Coding.self)
            XCTAssertNotNil(coding.id)
            jobID = coding.id
        })
        .test(.GET, "exp/jobs/\(jobID.uuidString)", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let coding = try $0.content.decode(JobExp.Coding.self)
            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, jobExpCoding.title)
            XCTAssertEqual(coding.companyName, jobExpCoding.companyName)
            XCTAssertEqual(coding.location, jobExpCoding.location)
            XCTAssertEqual(coding.startDate, jobExpCoding.startDate)
            XCTAssertEqual(coding.endDate, jobExpCoding.endDate)
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

        try app.test(.GET, "exp/jobs", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([JobExp.Coding].self)
            XCTAssertEqual(coding.count, 0)
        })
        .test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: assertHttpOk)
        .test(.GET, "exp/jobs", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode([JobExp.Coding].self)
            XCTAssertEqual(coding.count, 1)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        var jobID: String!

        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(JobExp.Coding.self)
            jobID = coding.id!.uuidString
        })
        .test(.PUT, "exp/jobs/" + jobID, headers: headers, beforeRequest: {
            try $0.content.encode(
                JobExp.Coding.init(
                    title: jobExpCoding.title,
                    companyName: jobExpCoding.companyName,
                    location: jobExpCoding.location,
                    startDate: jobExpCoding.startDate,
                    endDate: "2020-06-29",
                    industry: []
                )
            )
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(JobExp.Coding.self)

            XCTAssertNotNil(coding.id)
            XCTAssertNotNil(coding.userId)
            XCTAssertEqual(coding.title, jobExpCoding.title)
            XCTAssertEqual(coding.companyName, jobExpCoding.companyName)
            XCTAssertEqual(coding.location, jobExpCoding.location)
            XCTAssertEqual(coding.startDate, jobExpCoding.startDate)
            XCTAssertEqual(coding.endDate, "2020-06-29")
            XCTAssertEqual(coding.industry.count, 0)
            XCTAssertNil(coding.headline)
            XCTAssertNotNil(coding.responsibilities)
        })
    }

    func testDeleteWithInvalidJobID() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }).test(.DELETE, "exp/jobs/1", headers: headers, afterResponse: assertHttpNotFound)
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        var jobID: String!

        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: {
            let coding = try $0.content.decode(JobExp.Coding.self)
            jobID = coding.id!.uuidString
        }).test(.DELETE, "exp/jobs/" + jobID, headers: headers, afterResponse: assertHttpOk)
    }
}

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

let jobExpCoding = JobExp.Coding.init(company: "XXX", startAt: "2000-12-18", endAt: "now")

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

        try app.test(.POST, "exp/jobs", afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.GET, "exp/jobs/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.GET, "exp/jobs", afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.PUT, "exp/jobs/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.DELETE, "exp/jobs/" + uuid, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        })
    }

    func testCreate() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            try app?.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(JobExp.Coding.self)
                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.company, jobExpCoding.company)
                XCTAssertEqual(coding.startAt, jobExpCoding.startAt)
                XCTAssertEqual(coding.endAt, jobExpCoding.endAt)
                XCTAssertNil(coding.department)
                XCTAssertNil(coding.position)
                XCTAssertNil(coding.type)
            })
        })
    }

    func testQueryWithInvalidJobID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            try app?.test(.GET, "exp/jobs/1", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }

    func testQueryWithJobID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            var jobID: String!

            try app?.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                let coding = try $0.content.decode(JobExp.Coding.self)
                jobID = coding.id!.uuidString
            }).test(.GET, "exp/jobs/" + jobID, headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let coding = try $0.content.decode(JobExp.Coding.self)
                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.company, jobExpCoding.company)
                XCTAssertEqual(coding.startAt, jobExpCoding.startAt)
                XCTAssertEqual(coding.endAt, jobExpCoding.endAt)
                XCTAssertNil(coding.department)
                XCTAssertNil(coding.position)
                XCTAssertNil(coding.type)
            })
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            try app?.test(.GET, "exp/jobs", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode([JobExp.Coding].self)
                XCTAssertEqual(coding.count, 0)
            })
            .test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            })
            .test(.GET, "exp/jobs", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode([JobExp.Coding].self)
                XCTAssertEqual(coding.count, 1)
            })
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            let department = "Development"
            let position = "iOS"

            var jobID: String!

            try app?.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(JobExp.Coding.self)
                jobID = coding.id!.uuidString
            })
            .test(.PUT, "exp/jobs/" + jobID, headers: headers, beforeRequest: {
                try $0.content.encode(
                    JobExp.Coding.init(
                        company: jobExpCoding.company,
                        startAt: jobExpCoding.startAt,
                        endAt: jobExpCoding.endAt,
                        department: department,
                        position: position
                    )
                )
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(JobExp.Coding.self)

                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.company, jobExpCoding.company)
                XCTAssertEqual(coding.startAt, jobExpCoding.startAt)
                XCTAssertEqual(coding.endAt, jobExpCoding.endAt)
                XCTAssertEqual(coding.department, department)
                XCTAssertEqual(coding.position, position)
                XCTAssertNil(coding.type)
            })
        })
    }

    func testDeleteWithInvalidJobID() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            try app?.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }).test(.DELETE, "exp/jobs/1", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .notFound)
            })
        })
    }

    func testDelete() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, completion: { [weak app] in
            let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", $0))

            var jobID: String!

            try app?.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
                try $0.content.encode(jobExpCoding)
            }, afterResponse: {
                let coding = try $0.content.decode(JobExp.Coding.self)
                jobID = coding.id!.uuidString
            }).test(.DELETE, "exp/jobs/" + jobID, headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
            })
        })
    }
}

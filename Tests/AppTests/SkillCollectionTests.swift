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

class SkillCollectionTests: XCTestCase {

    let app = Application.init(.testing)
    let path = "skills"

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testAuthorizeRequire() throws {
        defer { app.shutdown() }

        try app.test(.POST, path, afterResponse: assertHttpUnauthorized)
            .test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
            .test(.DELETE, path + "/1", afterResponse: assertHttpUnauthorized)
    }

    func testCreate() throws {
        defer { app.shutdown() }

        try assertCreateSkill(app)
    }

    func testQuery() throws {
        defer { app.shutdown() }

        let saved = try assertCreateSkill(app)

        try app.test(.GET, path + "/1", afterResponse: assertHttpNotFound)
            .test(.GET, path + "/\(saved.id!)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.Coding.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertEqual(coding.profesional, saved.profesional)
            XCTAssertEqual(coding.workflow, saved.workflow)
        })
    }

    func testUpdate() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)
        let upgrade = Skill.Coding.init(profesional: nil, workflow: ["xxx", "xxxx"])

        let saved = try assertCreateSkill(app, headers: headers)
        
        try app.test(.PUT, path + "/1", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: assertHttpNotFound)
        .test(.PUT, path + "/\(saved.id!)", headers: headers, beforeRequest: {
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let coding = try $0.content.decode(Skill.Coding.self)

            XCTAssertEqual(coding.id, saved.id)
            XCTAssertNil(coding.profesional)
            XCTAssertEqual(coding.workflow, upgrade.workflow)
        })
    }

    func testDelete() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app)

        let saved = try assertCreateSkill(app, headers: headers)

        try app.test(.DELETE, path + "/1", headers: headers, afterResponse: assertHttpNotFound)
            .test(.DELETE, path + "/\(saved.id!)", headers: headers, afterResponse: assertHttpOk)
    }
}

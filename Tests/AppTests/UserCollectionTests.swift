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
    let path = "users"
    
    override func setUpWithError() throws {
        try bootstrap(app)
        
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testAuthorizeRequire() {
        defer { app.shutdown() }

        XCTAssertNoThrow(
            try app.test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreateWithInvalidUsername() throws {
        defer { app.shutdown() }
        
        try app.test(.POST, path, beforeRequest: {
            var invalid = userCreation
            invalid.username = ""
            try $0.content.encode(invalid)
        }, afterResponse: assertHttpBadRequest)
    }
    
    func testCreateWithInvalidPassword() throws {
        defer { app.shutdown() }
        
        try app.test(.POST, path, beforeRequest: {
            var invalid = userCreation
            invalid.password = "111"
            try $0.content.encode(invalid)
        }, afterResponse: assertHttpBadRequest)

    }
    
    func testCreateWithConflictUsername() throws {
        defer { app.shutdown() }
        
        try registUserAndLoggedIn(app)
        
        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(userCreation)
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
        
        try app.test(.GET, path + "/notfound", afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithUserID() throws {
        defer { app.shutdown() }
        
        try registUserAndLoggedIn(app, userCreation)
        
        try app.test(.GET, path + "/\(userCreation.username)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))
            
            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, userCreation.firstName)
            XCTAssertEqual(user.lastName, userCreation.lastName)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.social)
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.workExps)
        })
    }
    
    func testQueryWithUserIDAndQueryParameters() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app, userCreation)

        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true"
        try app.test(.GET, path + "/\(userCreation.username)\(query)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))
            
            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, userCreation.firstName)
            XCTAssertEqual(user.lastName, userCreation.lastName)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertEqual(user.social, [])
            XCTAssertEqual(user.projects, [])
            XCTAssertEqual(user.eduExps, [])
            XCTAssertEqual(user.workExps, [])
            XCTAssertNil(user.skill)
        })
    }

    func testQueryWithUserIDAndQueryParametersAfterAddChildrens() throws {
        defer { app.shutdown() }

        let headers = try registUserAndLoggedIn(app, userCreation)

        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)
        let workExp = try assertCreateWorkExperiance(app, headers: headers)
        let eduExp = try assertCreateEduExperiance(app, headers: headers)
        let proj = try assertCreateProj(app, headers: headers)
        let skill = try assertCreateSkill(app, headers: headers)

        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true"
        try app.test(.GET, path + "/\(userCreation.username)\(query)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))

            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, userCreation.firstName)
            XCTAssertEqual(user.lastName, userCreation.lastName)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertEqual(user.social?.count, 1)
            XCTAssertEqual(user.social?.first, socialNetworking)
            XCTAssertEqual(user.projects?.count, 1)
            XCTAssertEqual(user.projects?.first, proj)
            XCTAssertEqual(user.eduExps?.count, 1)
            XCTAssertEqual(user.eduExps?.first, eduExp)
            XCTAssertEqual(user.workExps?.count, 1)
            XCTAssertEqual(user.workExps?.first, workExp)
            XCTAssertEqual(user.skill, skill)
        })
    }

    func testQueryAll() throws {
        defer { app.shutdown() }
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 0)
        })
        
        try registUserAndLoggedIn(app)
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 1)
        })
    }
    
    func testQueryAllWithQueryParametersAfterAddChildrens() throws {
        defer { app.shutdown() }
        
        let headers = try registUserAndLoggedIn(app, userCreation)

        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)
        let workExpCoding = try assertCreateWorkExperiance(app, headers: headers)
        let eduExpCoding = try assertCreateEduExperiance(app, headers: headers)
        let projCoding = try assertCreateProj(app, headers: headers)
        let skillCoding = try assertCreateSkill(app, headers: headers)

        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true"
        try app.test(.GET, path + query, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let users = try $0.content.decode([User.Coding].self)
            XCTAssertEqual(users.count, 1)
            XCTAssertNotNil(users.first)
            
            let user = users.first!
            
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, userCreation.firstName)
            XCTAssertEqual(user.lastName, userCreation.lastName)
            XCTAssertNil(user.screenName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertEqual(user.social!.count, 1)
            XCTAssertEqual(user.social!.first, socialNetworking)
            XCTAssertEqual(user.eduExps!.count, 1)
            XCTAssertEqual(user.eduExps!.first, eduExpCoding)
            XCTAssertEqual(user.workExps!.count, 1)
            XCTAssertEqual(user.workExps!.first, workExpCoding)
            XCTAssertEqual(user.projects!.count, 1)
            XCTAssertEqual(user.projects!.first, projCoding)
            XCTAssertNotNil(user.skill)
            XCTAssertEqual(user.skill, skillCoding)
        })
    }
    
    func testUpdate() throws {
        defer { app.shutdown() }
        
        let headers = try registUserAndLoggedIn(app)
        let upgrade = User.Coding.init(
            firstName: "R",
            lastName: "J",
            screenName: "Jack",
            phone: "+1 888888888",
            emailAddress: "test@test.com",
            aboutMe: "HELLO WORLD !!!"
        )
        try app.test(.PUT, path + "/test", headers: headers, beforeRequest: {
            
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode(User.Coding.self))
            
            let user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, upgrade.firstName)
            XCTAssertEqual(user.lastName, upgrade.lastName)
            XCTAssertEqual(user.screenName, upgrade.screenName)
            XCTAssertEqual(user.phone, upgrade.phone)
            XCTAssertEqual(user.emailAddress, upgrade.emailAddress)
            XCTAssertEqual(user.aboutMe, upgrade.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.social)
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.workExps)
        })
    }
}

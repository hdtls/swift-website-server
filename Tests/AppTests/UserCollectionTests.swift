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
        }, afterResponse: assertHttpBadRequest)
    }
    
    func testCreateWithInvalidPassword() throws {
        defer { app.shutdown() }
        
        try app.test(.POST, "users", beforeRequest: {
            try $0.content.encode(User.Creation.init(username: "test", password: "111"))
        }, afterResponse: assertHttpBadRequest)
        
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
        
        try app.test(.GET, "users/didnotcreated", afterResponse: assertHttpNotFound)
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
        
        let headers = try registUserAndLoggedIn(app)
        
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
        
        try assertCreateSocial(app, headers: headers)
        
        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: assertHttpOk)
        .test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: assertHttpOk)
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
        
        let headers = try registUserAndLoggedIn(app)
        
        try app.test(.POST, "exp/jobs", headers: headers, beforeRequest: {
            try $0.content.encode(jobExpCoding)
        }, afterResponse: assertHttpOk)
        .test(.POST, "exp/edu", headers: headers, beforeRequest: {
            try $0.content.encode(eduExpCoding)
        }, afterResponse: assertHttpOk)
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
            XCTAssertEqual(edu.school, eduExpCoding.school)
            XCTAssertEqual(edu.degree, eduExpCoding.degree)
            XCTAssertEqual(edu.field, eduExpCoding.field)
            XCTAssertEqual(edu.startYear, eduExpCoding.startYear)
            XCTAssertNil(edu.endYear)
            XCTAssertEqual(edu.activities, eduExpCoding.activities)
            XCTAssertNil(edu.accomplishments)
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
        }, afterResponse: assertHttpUnauthorized)
    }
    
    func testUpdate() throws {
        defer { app.shutdown() }
        
        let headers = try registUserAndLoggedIn(app)
        
        try app.test(.PUT, "users/test", headers: headers, beforeRequest: {
            
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
    }
}

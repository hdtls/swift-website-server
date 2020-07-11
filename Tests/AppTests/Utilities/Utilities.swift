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

func assertHttpUnauthorized(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .unauthorized)
}

func assertHttpOk(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .ok)
}

func assertHttpNotFound(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .notFound)
}

func assertHttpServerError(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .internalServerError)
}

func assertHttpBadRequest(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .badRequest)
}

let userCreation = User.Creation.init(firstName: "J", lastName: "K", username: "test", password: "111111")
@discardableResult
func registUserAndLoggedIn(
    _ app: Application,
    _ userCreation: User.Creation = userCreation,
    headers: HTTPHeaders? = nil
) throws -> HTTPHeaders {

    var httpHeaders = headers
    guard httpHeaders == nil else {
        return httpHeaders!
    }

    try app.test(.POST, "users", beforeRequest: {
        try $0.content.encode(userCreation)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let authorizeMsg = try $0.content.decode(AuthorizeMsg.self)

        XCTAssertNotNil(authorizeMsg.accessToken)
        XCTAssertNotNil(authorizeMsg.user)
        XCTAssertNotNil(authorizeMsg.user.id)
        XCTAssertEqual(authorizeMsg.user.username, userCreation.username)
        XCTAssertEqual(authorizeMsg.user.firstName, userCreation.firstName)
        XCTAssertEqual(authorizeMsg.user.lastName, userCreation.lastName)
        XCTAssertNil(authorizeMsg.user.screenName)
        XCTAssertNil(authorizeMsg.user.phone)
        XCTAssertNil(authorizeMsg.user.emailAddress)
        XCTAssertNil(authorizeMsg.user.aboutMe)
        XCTAssertNil(authorizeMsg.user.location)
        XCTAssertNil(authorizeMsg.user.eduExps)
        XCTAssertNil(authorizeMsg.user.workExps)
        XCTAssertNil(authorizeMsg.user.hobbies)

        httpHeaders = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Bearer " + authorizeMsg.accessToken))
    })

    return httpHeaders!
}

let socialNetworkingService = SocialNetworkingService.Coding.init(type: .twitter)
@discardableResult
func assertCreateSocialNetworkingService(
    _ app: Application,
    service: SocialNetworkingService.Coding = socialNetworkingService
) throws -> SocialNetworkingService.Coding {

    var service: SocialNetworkingService.Coding!

    try app.test(.POST, "social/services", beforeRequest: {
        try $0.content.encode(socialNetworkingService)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.type)

        service = coding
    })

    return service
}

@discardableResult
func assertCreateSocialNetworking(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> SocialNetworking.Coding {

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: SocialNetworking.Coding!

    let service = try assertCreateSocialNetworkingService(app)

    try app.test(.POST, "social", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(
            SocialNetworking.Coding.init(url: "https://twitter.com/uid", service: service)
        )
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)
        coding = try $0.content.decode(SocialNetworking.Coding.self)

        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.url, "https://twitter.com/uid")
        XCTAssertNotNil(coding.service)
        XCTAssertEqual(coding.service?.id, service.id)
    })

    return coding
}

@discardableResult
func assertCreateIndustry(
    _ app: Application,
    industry: Industry.Coding? = nil
) throws -> Industry.Coding {

    var coding: Industry.Coding!

    try app.test(.POST, Industry.schema, beforeRequest: {
        try $0.content.encode(industry ?? Industry.Coding.init(title: "International Trade & Development"))
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Industry.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.title, industry?.title ?? "International Trade & Development")

    })

    return coding
}

let workExpCoding = WorkExp.Coding.init(
    title: "iOS Developer",
    companyName: "XXX",
    location: "XXX",
    startDate: "2020-02-20",
    endDate: "-",
    industry: [
        Industry.Coding.init(title: "International Trade & Development")
    ]
)
@discardableResult
func assertCreateWorkExperiance(
    _ app: Application,
    headers: HTTPHeaders? = nil,
    exp: WorkExp.Coding = workExpCoding
) throws -> WorkExp.Coding {
    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)
    let industry = try assertCreateIndustry(app, industry: exp.industry.first)

    var coding: WorkExp.Coding!

    try app.test(.POST, "exp/works", headers: httpHeaders, beforeRequest: {
        var workExpCoding = exp
        workExpCoding.industry = [industry]
        try $0.content.encode(workExpCoding)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(WorkExp.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.title, exp.title)
        XCTAssertEqual(coding.companyName, exp.companyName)
        XCTAssertEqual(coding.location, exp.location)
        XCTAssertEqual(coding.startDate, exp.startDate)
        XCTAssertEqual(coding.endDate, exp.endDate)
        XCTAssertEqual(coding.industry.count, 1)
        XCTAssertEqual(coding.industry.first!.id, industry.id)
        XCTAssertEqual(coding.industry.first!.title, industry.title)
        XCTAssertNil(coding.headline)
        XCTAssertNil(coding.responsibilities)
    })

    return coding
}

let skill = Skill.Coding.init(profesional: ["xxx"], workflow: ["xxx"])
@discardableResult
func assertCreateSkill(
    _ app: Application,
    headers: HTTPHeaders? = nil,
    skill: Skill.Coding = skill
) throws -> Skill.Coding {

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Skill.Coding!

    try app.test(.POST, "skills", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(skill)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Skill.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.profesional, skill.profesional)
        XCTAssertEqual(coding.workflow, skill.workflow)
    })

    return coding
}

let proj = Project.Coding.init(name: "proj", summary: "proj_summary", startDate: "start_date", endDate: "end_date")
@discardableResult
func assertCreateProj(
    _ app: Application,
    headers: HTTPHeaders? = nil,
    proj: Project.Coding = proj
) throws -> Project.Coding {

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Project.Coding!

    try app.test(.POST, "projects", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(proj)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Project.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.name, proj.name)
        XCTAssertEqual(coding.categories, proj.categories)
        XCTAssertEqual(coding.summary, proj.summary)
        XCTAssertEqual(coding.startDate, proj.startDate)
        XCTAssertEqual(coding.endDate, proj.endDate)
        XCTAssertNotNil(coding.userId)
    })

    return coding
}

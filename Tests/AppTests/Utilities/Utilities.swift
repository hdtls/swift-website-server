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

func registUserAndLoggedIn(
    _ app: Application,
    _ username: String = "test",
    _ password: String = "111111",
    headers: HTTPHeaders? = nil,
    completion: ((HTTPHeaders) throws -> Void)? = nil
) throws {

    guard headers == nil else {
        try completion?(headers!)
        return
    }

    try app.test(.POST, "users", beforeRequest: {
        try $0.content.encode(User.Creation.init(username: username, password: password))
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let authorizeMsg = try $0.content.decode(AuthorizeMsg.self)

        XCTAssertNotNil(authorizeMsg.accessToken)
        XCTAssertNotNil(authorizeMsg.user)
        XCTAssertNotNil(authorizeMsg.user.id)
        XCTAssertEqual(authorizeMsg.user.username, username)
        XCTAssertNil(authorizeMsg.user.name)
        XCTAssertNil(authorizeMsg.user.screenName)
        XCTAssertNil(authorizeMsg.user.phone)
        XCTAssertNil(authorizeMsg.user.emailAddress)
        XCTAssertNil(authorizeMsg.user.aboutMe)
        XCTAssertNil(authorizeMsg.user.location)
        XCTAssertNil(authorizeMsg.user.eduExps)
        XCTAssertNil(authorizeMsg.user.jobExps)

        try completion?(HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Bearer " + authorizeMsg.accessToken)))
    })
}

func assertCreateNetworkingService(
    _ app: Application,
    service: SocialNetworkingService.Coding = socialNetworkingService,
    completion: ((SocialNetworkingService.IDValue) throws -> Void)? = nil) throws {

    try app.test(.POST, "social/services", beforeRequest: {
        try $0.content.encode(socialNetworkingService)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.type)
        XCTAssertEqual(coding.html, socialNetworkingService.html)
        XCTAssertNil(coding.imageUrl)

        try completion?(coding.id!)
    })
}

func assertCreateSocial(
    _ app: Application,
    headers: HTTPHeaders? = nil,
    completion: ((HTTPHeaders, Social.Coding) throws -> Void)? = nil
) throws {

    try assertCreateNetworkingService(app, completion: { [unowned app] serviceID in
        try registUserAndLoggedIn(app, headers: headers, completion: { headers in
            try app.test(.POST, "social", headers: headers, beforeRequest: {
                try $0.content.encode(Social.Coding.init(url: "https://twitter.com/uid", networkingServiceId: serviceID))
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let coding = try $0.content.decode(Social.Coding.self)

                XCTAssertNotNil(coding.id)
                XCTAssertNotNil(coding.userId)
                XCTAssertEqual(coding.url, "https://twitter.com/uid")
                XCTAssertNotNil(coding.networkingService)
                XCTAssertEqual(coding.networkingService?.id, serviceID)

                try completion?(headers, coding)
            })
        })
    })
}

@discardableResult
func assertCreateIndustry(
    _ app: Application,
    completion: ((Industry.Coding) throws -> Void)? = nil
) throws -> XCTApplicationTester {

    return try app.test(.POST, Industry.schema, beforeRequest: {
        try $0.content.encode(Industry.Coding.init(title: "International Trade & Development"))
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let coding = try $0.content.decode(Industry.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.title, "International Trade & Development")
        try completion?(coding)
    })
}

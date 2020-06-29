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

func registUserAndLoggedIn(
    _ app: Application,
    _ username: String = "test",
    _ password: String = "111111",
    completion: ((String) throws -> Void)? = nil
) throws {

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
        XCTAssertNil(authorizeMsg.user.profileBackgroundColor)
        XCTAssertNil(authorizeMsg.user.profileBackgroundImageUrl)
        XCTAssertNil(authorizeMsg.user.profileBackgroundTile)
        XCTAssertNil(authorizeMsg.user.profileImageUrl)
        XCTAssertNil(authorizeMsg.user.profileBannerUrl)
        XCTAssertNil(authorizeMsg.user.profileLinkColor)
        XCTAssertNil(authorizeMsg.user.profileTextColor)
        XCTAssertNil(authorizeMsg.user.webLinks)
        XCTAssertNil(authorizeMsg.user.eduExps)
        XCTAssertNil(authorizeMsg.user.jobExps)

        try completion?("Bearer " + authorizeMsg.accessToken)
    })
}

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

class LogCollectionTests: XCTestCase {

    let app = Application.init(.testing)

    override func setUpWithError() throws {
        try bootstrap(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    func testLoginWithWrongMsg() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        let wrongPasswordHeader = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTEx"))
        let wrongUsernameHeader = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDE6MTExMTEx"))

        try app.test(.POST, "login", headers: wrongPasswordHeader, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        }).test(.POST, "login", headers: wrongUsernameHeader, afterResponse: {
            XCTAssertEqual($0.status, .unauthorized)
        })
    }

    func testLogin() throws {
        defer { app.shutdown() }

        try registUserAndLoggedIn(app)

        let headers = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Basic dGVzdDoxMTExMTE="
        ))
        try app.test(.POST, "login", headers: headers, afterResponse: {
            XCTAssertEqual($0.status, .ok)
        })
    }
}

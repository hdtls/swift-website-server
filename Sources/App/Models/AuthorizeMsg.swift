//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Netbot Ltd. and the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Vapor

struct AuthorizeMsg: Content {
    let user: User.Body
    let accessToken: String

    init(user: User.Body, token: Token) {
        self.user = user
        self.accessToken = token.token
    }
}

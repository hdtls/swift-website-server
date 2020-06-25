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

class LogCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.grouped(User.authenticator()).on(.POST, "login", use: logIn(_:))
        routes.grouped(Token.authenticator()).on(.POST, "logout", use: logOut(_:))
    }

    func logIn(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        let user = try req.auth.require(User.self)
        let token = try Token.init(user)

        return token.save(on: req.db)
            .map({
                AuthorizeMsg.init(user: User.Body.init(user), token: token)
            })
    }

    func logOut(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        try req.auth.require(Token.self)
            .delete(on: req.db)
            .map({ .ok })
    }
}

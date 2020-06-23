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

class UserCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.on(.POST, use: create)

        let pwdProtectedRoutes = users.grouped(User.authenticator())
        pwdProtectedRoutes.on(.POST, "login", use: login)

        let tokenProtectedRoutes = users.grouped(Token.authenticator())
        tokenProtectedRoutes.on(.GET, use: index)
        tokenProtectedRoutes.on(.GET, ":userID", use: index)
    }

    func create(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        try User.Registration.validate(req)
        
        let user = try User.init(req.content.decode(User.Registration.self))

        var token: Token!

        return User.query(on: req.db)
            .filter(\.$username, .equal, user.username)
            .first()
            .flatMap({
                // If there is already have a user and username same as `user.username` just throw a msg.
                guard $0 == nil else {
                    return req.eventLoop.makeFailedFuture(Abort.init(.conflict, reason: "Username already taken"))
                }
                return user.save(on: req.db)
            })
            .flatMap({
                guard let unsafeToken = try? Token.init(user) else {
                    return req.eventLoop.makeFailedFuture(Abort.init(.internalServerError))
                }
                token = unsafeToken
                return token.save(on: req.db)
            })
            .map({
                AuthorizeMsg.init(user: User.Body.init(user), token: token)
            })
    }

    /// Query user from `ID` or `username`.
    func index(_ req: Request) -> EventLoopFuture<[User.Body]> {

        guard let userID = req.parameters.get("userID") else {
            return User.query(on: req.db).all().map({ $0.map(User.Body.init) })
        }

        guard let userId = User.IDValue.init(userID) else {
            return User.query(on: req.db)
                .filter(\.$username, .equal, userID)
                .all()
                .map({ $0.map(User.Body.init) })
        }

        return User.query(on: req.db)
            .filter(\.$id, .equal, userId)
            .all()
            .map({ $0.map(User.Body.init) })
    }


    func login(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        let user = try req.auth.require(User.self)
        let token = try Token.init(user)

        return token.save(on: req.db)
            .map({
                AuthorizeMsg.init(user: User.Body.init(user), token: token)
            })
    }

}

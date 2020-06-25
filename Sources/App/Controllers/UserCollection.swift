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
        users.on(.POST, use: create(_:))
        users.on(.GET, use: queryAllUsers(_:))
        users.on(.GET, ":userID", use: queryUser(_:))
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

    func queryUser(_ req: Request) -> EventLoopFuture<User.Body> {
        return queryAllUsers(req).map({ $0.first }).unwrap(or: Abort.init(.notFound))
    }

    /// Query users, if `userID` exist add `userID` to filter .
    func queryAllUsers(_ req: Request) -> EventLoopFuture<[User.Body]> {

        var queryBuilder = User.query(on: req.db)

        // Logged in user can query `User` by `id` or unique property `username`.
        // User ID has higher priority to be used for query.
        if let userID = req.parameters.get("userID", as: User.IDValue.self) {
            queryBuilder = queryBuilder.filter(\.$id, .equal, userID)
        } else if let userID = req.parameters.get("userID") {
            queryBuilder = queryBuilder.filter(\.$username, .equal, userID)
        }

        // Include job experiances to query.
        if req.parameters.get("include_job_exp") ?? false {
            queryBuilder.with(\.$jobExps)
        }

        // Include edu experiances to query.
        if req.parameters.get("include_edu_exp") ?? false {
            queryBuilder.with(\.$eduExps)
        }

        return queryBuilder
            .all()
            .map({ $0.map(User.Body.init) })
    }
}

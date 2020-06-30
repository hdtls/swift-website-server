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

import Vapor

class UserCollection: RouteCollection {

    let restfulIDKey = "userID"

    func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped("users")

        let path = PathComponent.init(stringLiteral: ":" + restfulIDKey)

        users.on(.POST, use: create)
        users.on(.GET, use: readAll)
        users.on(.GET, path, use: read)

        let trusted = users.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])
        trusted.on(.PUT, path, use: update)
    }

    /// Register new user with `User.Creation` msg. when success a new user and token is registed.
    /// - seealso: `User.Creation` for more creation content info.
    /// - note: We make `username` unique so if the `username` already taken an `conflic` statu will be
    /// send to custom.
    func create(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        try User.Creation.validate(req)
        
        let user = try User.init(req.content.decode(User.Creation.self))

        var token: Token!

        return User.query(on: req.db)
            .filter(\.$username, .equal, user.username)
            .first()
            .flatMap({
                // If there is already have a user and username same as
                // `user.username` just throw a msg.
                guard $0 == nil else {
                    let error = Abort(.conflict, reason: "Username already taken")
                    return req.eventLoop.makeFailedFuture(error)
                }
                return user.save(on: req.db)
            })
            .flatMap({
                guard let unsafeToken = try? Token.init(user) else {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                }
                token = unsafeToken
                return token.save(on: req.db)
            })
            .flatMapThrowing({
                try AuthorizeMsg.init(user: user.__reverted(), token: token)
            })
    }

    /// Query user with specified`userID`.
    /// - seealso: `UserCollection.queryAllUsers(_:)`
    func read(_ req: Request) -> EventLoopFuture<User.Coding> {
        readAll(req)
            .map({ $0.first })
            .unwrap(or: Abort.init(.notFound))
    }

    /// Query users, if `userID` exist add `userID` to filter . there are three query parameters,
    /// `include_job_exp`:  default is `false`, if `true` the result of user will include user's job experiances.
    /// `include_edu_exp`:  default is `false`, if `true` the result of user will include user's education experiances.
    /// `include_web_links`:  default is `false`, if `true` the result of user will include user's web links.
    /// - note: This is a mix function the `userID` is optional value.
    func readAll(_ req: Request) -> EventLoopFuture<[User.Coding]> {

        var queryBuilder = User.query(on: req.db)

        // Logged in user can query `User` by `id` or unique property `username`.
        // User ID has higher priority to be used for query.
        if let userID = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder = queryBuilder.filter(\.$id, .equal, userID)
        } else if let userID = req.parameters.get(restfulIDKey) {
            queryBuilder = queryBuilder.filter(\.$username, .equal, userID)
        }

        // Include job experiances to query if the key `include_job_exp` exist.
        if (try? req.query.get(Bool.self, at: "include_job_exp")) ?? false {
            queryBuilder.with(\.$jobExps)
        }

        // Include edu experiances to query if the key `include_job_exp` exist.
        if (try? req.query.get(Bool.self, at: "include_edu_exp")) ?? false {
            queryBuilder.with(\.$eduExps)
        }

        if (try? req.query.get(Bool.self, at: "include_social")) ?? false {
            queryBuilder.with(\.$social) {
                $0.with(\.$networkingService)
            }
        }

        return queryBuilder
            .all()
            .flatMapEachThrowing({
                try $0.__reverted()
            })
    }

    /// Update exists user with `User.Coding` which contain all properties that user need updated.
    func update(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        let userId = try req.auth.require(User.self).requireID()
        let coding = try req.content.decode(User.Coding.self)
        let upgrade = try User.__converted(coding)

        return User.find(userId, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ saved -> EventLoopFuture<User> in
                saved.__merge(upgrade)
                let newValue = saved
                return newValue.update(on: req.db).map({ newValue })
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }
}

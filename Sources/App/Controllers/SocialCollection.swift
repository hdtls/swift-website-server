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
import Fluent

class SocialCollection: UserChildCollection {
    typealias T = Social

    var pidFieldKey: FieldKey = T.FieldKeys.user.rawValue

    func boot(routes: RoutesBuilder) throws {
        let trusted = routes.grouped("social").grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.GET, use: readAll)

        let path = PathComponent.init(stringLiteral: ":" + restfulIDKey)
        trusted.on(.GET, path, use: read)
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.Coding.self)
        let model = try T.__converted(coding)
        model.$user.id = try user.requireID()

        return model.save(on: req.db)
            .flatMap({
                // Make sure `$socialNetworkingService` has been eager loaded
                // before try `model.__reverted()`.
                model.$networkingService.get(on: req.db)
            })
            .flatMapThrowing({ _ in
                try model.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .filter(pidFieldKey, .equal, userID)
            .with(\.$networkingService)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMapThrowing({
                try $0.__reverted()
            })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .with(\.$networkingService)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .filter(pidFieldKey, .equal, userID)
            .with(\.$networkingService)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.__merge(upgrade)
                let newValue = saved
                return newValue.update(on: req.db)
                    .map({ newValue })
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }
}

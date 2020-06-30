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
import enum Fluent.FieldKey

class SocialCollection: RestfulCollection {

    typealias T = Social

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
                model.$socialNetworkingService.get(on: req.db)
            })
            .flatMapThrowing({ _ in
                try model.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id, .equal, id)
            .with(\.$socialNetworkingService)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMapThrowing({
                try $0.__reverted()
            })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        return T.query(on: req.db)
            .with(\.$socialNetworkingService)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        var coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ exp -> T in
                try exp.__merge(upgrade)
                coding = try exp.__reverted()
                return exp
            })
            .flatMap({ $0.update(on: req.db) })
            .map({ coding })
    }
}

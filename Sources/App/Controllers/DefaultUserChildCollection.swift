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

protocol UserChild: Model, Transfer where IDValue: LosslessStringConvertible {
    var _$user: Parent<User> { get }
}

/// This protocol define user children restful route collection.
/// because all `CRUD` request require data owned by userself so those operation all require authorized.
protocol UserChildCollection: RestfulCollection where T: UserChild {
    var pidFieldKey: FieldKey { get }
}

extension UserChildCollection {
    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.Coding.self)
        let exp = try T.__converted(coding)
        exp._$user.id = try user.requireID()
        return exp.save(on: req.db)
            .flatMapThrowing({
                try exp.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.__reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let userID = try req.auth.require(User.self).requireID()
        let coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.__merge(upgrade)
                let newValue = saved
                return saved.update(on: req.db).map({ newValue })
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        guard let expID = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(.id, .equal, expID)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}

class DefaultUserChildCollection<T: UserChild>: UserChildCollection {

    var path: [PathComponent]
    let pidFieldKey: FieldKey

    init(path: PathComponent..., pidFieldKey: FieldKey = "user_id") {
        self.path = path
        self.pidFieldKey = pidFieldKey
    }

    func boot(routes: RoutesBuilder) throws {
        var routes = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])

        path.forEach({
            routes = routes.grouped($0)
        })

        routes.on(.POST, use: create(_:))
        routes.on(.GET, use: readAll(_:))
        routes.on(.GET, PathComponent.init(stringLiteral: ":" + restfulIDKey), use: read(_:))
        routes.on(.PUT, PathComponent.init(stringLiteral: ":" + restfulIDKey), use: update(_:))
        routes.on(.DELETE, PathComponent.init(stringLiteral: ":" + restfulIDKey), use: delete(_:))
    }
}

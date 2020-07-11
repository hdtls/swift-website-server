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

class WorkExpCollection: RouteCollection, RestfulApi {
    typealias T = WorkExp

    var pidFieldKey: FieldKey = T.FieldKeys.user.rawValue

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("works")

        routes.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.Coding.self)

        let exp = try T.__converted(coding)

        let industries = try coding.industry.map({ coding -> Industry in
            // `Industry.id` is not required by `Industry.__converted(_:)`, but
            // required by create relation of `workExp` and `industry`, so we will
            // add additional check to make sure it have `id` to attach with.
            guard let coding.id != nil else {
                throw Abort.init(.badRequest, reason: "Value required for key 'Industry.id'")
            }
            return try Industry.__converted(coding)
        })
        
        exp.$user.id = try user.requireID()

        return exp.save(on: req.db)
            .flatMap({
                exp.$industry.attach(industries, on: req.db)
            })
            .flatMap({
                exp.$industry.get(on: req.db)
            })
            .flatMapThrowing({ _ in
                try exp.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .with(\.$industry)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.__reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .with(\.$industry)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)
        let industries = try coding.industry.map({ coding -> Industry in
            // `Industry.id` is not required by `Industry.__converted(_:)`, but
            // required by create relation of `workExp` and `industry`, so we will
            // add additional check to make sure it have `id` to attach with.
            guard coding.id != nil else {
                throw Abort.init(.badRequest, reason: "Value required for key 'Industry.id'")
            }
            return try Industry.__converted(coding)
        })

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .with(\.$industry)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.__merge(upgrade)

                let difference = industries.difference(from: saved.industry) {
                    $0.id == $1.id
                }

                return EventLoopFuture<Void>.andAllSucceed(difference.map({
                    switch $0 {
                    case .insert(offset: _, element: let industry, associatedWith: _):
                        return saved.$industry.attach(industry, on: req.db)
                    case .remove(offset: _, element: let industry, associatedWith: _):
                        return saved.$industry.detach(industry, on: req.db)
                    }
                }), on: req.eventLoop)
                .flatMap({
                    saved.$industry.get(reload: true, on: req.db)
                })
                .flatMap({ _ in
                    saved.update(on: req.db)
                })
                .map({ saved })
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
            .with(\.$industry)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ exp in
                exp.$industry.detach(exp.industry, on: req.db).flatMap({
                    exp.delete(on: req.db)
                })
            })
            .map({ .ok })
    }
}

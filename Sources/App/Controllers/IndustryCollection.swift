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

class IndustryCollection: RouteCollection, RestfulApi {
    typealias T = Industry

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.init(stringLiteral: T.schema))

        // TODO: `CUD` should require admin.
        routes.on(.POST, use: create)
        routes.on(.GET, use: readAll)

        let path = PathComponent.init(stringLiteral: ":\(restfulIDKey)")
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let coding = try req.content.decode(T.Coding.self)
        let industry = try T.__converted(coding)

        return T.query(on: req.db)
            .filter(T.FieldKeys.title.rawValue, .equal, industry.title)
            .first()
            .flatMap({
                // `title` is unique.
                guard $0 == nil else {
                    let error = Abort(.conflict, reason: "title already taken")
                    return req.eventLoop.makeFailedFuture(error)
                }
                return industry.save(on: req.db)
            })
            .flatMapThrowing({
                try industry.__reverted()
            })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.__merge(upgrade)
                return saved.update(on: req.db).map({ saved })
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }
}

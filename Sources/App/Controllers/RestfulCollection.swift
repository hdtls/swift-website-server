//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Vapor
import Fluent

/// ID path for uri
let idKey = "id"

/// Restful style route collection
/// by default it provide `CRUD` method if `T.IDValue` is `LosslessStringConvertible`
protocol RestfulCollection: RouteCollection {
    associatedtype T: Model, Transfer

    /// Create new model
    /// This operation will decode request content with `T.Coding` and transfer it to type `T`
    /// then save to db after that a saved model reverted object will be return for user.
    func create(_ req: Request) throws -> EventLoopFuture<T.Coding>

    /// Read model by given `id`.
    /// This operation will request model id as parameter, if db don't have a model type with `T`
    /// and id equal to `id` a `404 notFound` will be send to user, otherwise return model's
    /// reverted object to user.
    func read(_ req: Request) throws -> EventLoopFuture<T.Coding>

    /// Read all model type with `T`.
    /// Query all models and return all model reverted object to user.
    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]>

    /// Update a model with given `id`
    /// This operation will query model with `id` first, if there is no model return `404` error
    /// otherwise update that model with transfered new model, final return new model's reverted
    /// object to user.
    /// - warning: This operation will change db model value, be careful if you want do this.
    func update(_ req: Request) throws -> EventLoopFuture<T.Coding>

    /// Delete a model with given `id`
    /// First this operation will query model with `id`, if there is no model with `id` `404`
    /// error will be return otherwise delete model from db.
    /// - warning: This operation is dangerous it will delete mdoel from db and can't be
    /// reverted.
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus>
}

/// Default `CRUD` implementation.
extension RestfulCollection where T.IDValue: LosslessStringConvertible {
    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let coding = try req.content.decode(T.Coding.self)
        let exp = try T.__converted(coding)
        return exp.save(on: req.db)
            .flatMapThrowing({
              try exp.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {

        guard let id = req.parameters.get(idKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.__reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        return T.query(on: req.db)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        var coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(idKey, as: T.IDValue.self) else {
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

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let id = req.parameters.get(idKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.find(id, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}

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

/// In progress
/// admin user request.
class SocialNetworkingServiceCollection: RouteCollection, RestfulApi {
    typealias T = SocialNetworkingService

    func boot(routes: RoutesBuilder) throws {

        let routes = routes.grouped("social", "services")

        let path = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, use: readAll)
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<SocialNetworking.Service.Coding> {
        let coding = try req.content.decode(T.Coding.self)
        guard coding.type != nil else {
            throw Abort.init(.badRequest, reason: "Value required for key 'type'")
        }
        let model = try T.__converted(coding)
        return model.save(on: req.db)
            .flatMapThrowing({
                try model.__reverted()
            })
    }
}

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
class SocialNetworkingServiceCollection: RestfulCollection {
    typealias T = SocialNetworkingService

    func boot(routes: RoutesBuilder) throws {

        let routes = routes.grouped("social", "services")

        let path = PathComponent.init(stringLiteral: ":" + restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, use: readAll)
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }
}

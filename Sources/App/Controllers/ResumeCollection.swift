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

class ResumeCollection: RouteCollection {

    let restfulIDKey = "userID"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("users", .parameter(restfulIDKey), "resume")
        routes.on(.GET, use: read)
    }

    func read(_ req: Request) throws -> EventLoopFuture<[Resume.Module]> {
        let queryBuilder = User.query(on: req.db)

        // Support for `id` and `username` check.
        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            queryBuilder.filter(User.FieldKeys.username.rawValue, .equal, id)
        } else {
            throw Abort(.notFound)
        }

        return queryBuilder
            .with(\.$eduExps)
            .with(\.$workExps) {
                $0.with(\.$industry)
            }
            .with(\.$social) {
                $0.with(\.$service)
            }
            .with(\.$skill)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({
                try $0.__reverted()
            })
            .map({
                [
                    Resume.Module.init(
                        id: 0,
                        title: "about",
                        profile: User.Coding.init(
                            firstName: $0.firstName,
                            lastName: $0.lastName,
                            phone: $0.phone,
                            emailAddress: $0.emailAddress,
                            aboutMe: $0.aboutMe,
                            location: $0.location,
                            social: $0.social
                        )
                    ),
                    Resume.Module.init(id: 1, title: "experiance", works: $0.workExps),
                    Resume.Module.init(id: 2, title: "education", edu: $0.eduExps),
                    Resume.Module.init(id: 3, title: "skill", skill: $0.skill),
                    Resume.Module.init(id: 4, title: "interests", hobbies: $0.hobbies)
                ]
            })
    }
}

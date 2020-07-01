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

    let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("resume")

        let path = PathComponent.init(stringLiteral: ":/\(restfulIDKey)")
        routes.on(.GET, path, use: read)
    }

    func read(_ req: Request) throws -> EventLoopFuture<[Resume.Module]> {
        guard let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) else {
            throw Abort(.notFound)
        }
        return User.query(on: req.db)
            .filter(\._$id == id)
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

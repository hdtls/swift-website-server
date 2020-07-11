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

import Fluent

extension SocialNetworkingService {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {

            var enumBuilder = database.enum(FieldKeys.type.rawValue.description)

            SocialNetworkingService.ServiceType.allCases.forEach({
                enumBuilder = enumBuilder.case($0.rawValue)
            })

            return enumBuilder.create()
                .flatMap({
                    database.schema(SocialNetworkingService.schema)
                        .id()
                        .field(FieldKeys.type.rawValue, $0, .required)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(SocialNetworkingService.schema).delete()
                .flatMap({
                    database.enum(FieldKeys.type.rawValue.description).delete()
                })
        }
    }
}

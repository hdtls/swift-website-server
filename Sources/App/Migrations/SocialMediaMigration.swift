//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Netbot Ltd. and the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Fluent

extension SocialMedia {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {

            var enumBuilder = database.enum(SocialMedia.MediaType.name.description)

            SocialMedia.MediaType.allCases.forEach({
                enumBuilder = enumBuilder.case($0.rawValue)
            })

            return enumBuilder.create()
                .flatMap({
                    database.schema(SocialMedia.schema)
                        .id()
                        .field(SocialMedia.MediaType.name, $0, .required)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(SocialMedia.schema).delete()
                .flatMap({
                    database.enum(SocialMedia.MediaType.name.description).delete()
                })
        }
    }
}

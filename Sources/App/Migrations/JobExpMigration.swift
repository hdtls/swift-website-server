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

extension JobExp {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(JobExp.schema)
                .id()
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .field(FieldKeys.company.rawValue, .string, .required)
                .field(FieldKeys.startAt.rawValue, .string, .required)
                .field(FieldKeys.endAt.rawValue, .string, .required)
                .field(FieldKeys.type.rawValue, .string)
                .field(FieldKeys.department.rawValue, .string)
                .field(FieldKeys.position.rawValue, .string)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(JobExp.schema).delete()
        }
    }
}

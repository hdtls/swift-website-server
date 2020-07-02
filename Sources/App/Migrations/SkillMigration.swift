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

extension Skill {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Skill.schema)
                .id()
                .field(FieldKeys.profesional.rawValue, .array(of: .string))
                .field(FieldKeys.workflow.rawValue, .array(of: .string))
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Skill.schema).delete()
        }
    }
}

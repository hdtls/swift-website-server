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

extension EducationalExp {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(EducationalExp.schema)
                .id()
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .field(FieldKeys.school.rawValue, .string, .required)
                .field(FieldKeys.degree.rawValue, .string, .required)
                .field(FieldKeys.field.rawValue, .string, .required)
                .field(FieldKeys.startYear.rawValue, .string)
                .field(FieldKeys.endYear.rawValue, .string)
                .field(FieldKeys.grade.rawValue, .string)
                .field(FieldKeys.activities.rawValue, .array(of: .string))
                .field(FieldKeys.accomplishments.rawValue, .array(of: .string))
                .field(FieldKeys.media.rawValue, .string)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(EducationalExp.schema).delete()
        }
    }
}

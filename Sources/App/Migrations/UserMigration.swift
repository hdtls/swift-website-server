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

extension User {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema)
                .id()
                .field(FieldKeys.username.rawValue, .string, .required)
                .unique(on: FieldKeys.username.rawValue)
                .field(FieldKeys.pwd.rawValue, .string, .required)
                .field(FieldKeys.firstName.rawValue, .string, .required)
                .field(FieldKeys.lastName.rawValue, .string, .required)
                .field(FieldKeys.screenName.rawValue, .string)
                .field(FieldKeys.phone.rawValue, .string)
                .field(FieldKeys.emailAddress.rawValue, .string)
                .field(FieldKeys.aboutMe.rawValue, .string)
                .field(FieldKeys.location.rawValue, .string)
                .field(FieldKeys.createdAt.rawValue, .datetime, .required)
                .field(FieldKeys.updatedAt.rawValue, .datetime, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema).delete()
        }
    }
}

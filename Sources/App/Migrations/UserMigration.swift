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

class UserMigration: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .field("id", .uuid, .identifier(auto: true))
            .field("username", .string, .required)
            .unique(on: "username")
            .field("pwd_hash", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }

}

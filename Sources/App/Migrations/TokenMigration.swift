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

class TokenMigration: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .field("id", .uuid, .identifier(auto: true))
            .field("user_id", .uuid, .references(User.schema, "id"))
            .field("token", .string, .required)
            .unique(on: "token")
            .field("expires_date", .date)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}

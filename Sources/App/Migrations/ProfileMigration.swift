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

//struct ProfileMigration: Migration {
//
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        return database.schema(Profile.schema)
//            .id()
//            .field("fisrt_name", .string)
//            .field("last_name", .string)
//            .field("address", .string)
//            .field("phone", .string)
//            .field("email", .string)
//            .field("intro", .string)
//            .create()
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        return database.schema(Profile.schema).delete()
//    }
//}

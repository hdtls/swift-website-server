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

extension JobExpIndustrySiblings {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(JobExpIndustrySiblings.schema)
                .id()
                .field(FieldKeys.jobExp.rawValue, .uuid, .required)
                .field(FieldKeys.industry.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(JobExpIndustrySiblings.schema).delete()
        }
    }
}

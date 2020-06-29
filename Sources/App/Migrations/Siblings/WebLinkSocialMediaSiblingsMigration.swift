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

extension WebLinkSocialMediaSiblings {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WebLinkSocialMediaSiblings.schema)
                .id()
                .field(FieldKeys.webLink.rawValue, .uuid, .required)
                .field(FieldKeys.socialMedia.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WebLinkSocialMediaSiblings.schema).delete()
        }
    }
}

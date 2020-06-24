//
//  File.swift
//  
//
//  Created by melvyn on 6/25/20.
//

import Fluent

extension WebLink {

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WebLink.schema)
                .id()
                .field(FieldKeys.user.rawValue, .uuid, .required)
                .field(FieldKeys.url.rawValue, .string, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WebLink.schema).delete()
        }
    }
}

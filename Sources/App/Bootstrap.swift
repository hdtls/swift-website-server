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

import Vapor
import Fluent
import FluentMySQLDriver

typealias Env = Environment

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    app.http.server.configuration.port = 8181
    
    // JSON configuration
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Middlewares configuration
    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.mysql(
        hostname: "127.0.0.1",
        port: app.environment == .testing ? 3308 : (app.environment == .development ? 3307 : 3306),
        username: "vapor",
        password: "vapor.mysql",
        database: "website",
        tlsConfiguration: .none
        ), as: .mysql)

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
    app.migrations.add(WorkExp.migration)
    app.migrations.add(SocialNetworking.migration)
    app.migrations.add(Industry.migration)
    app.migrations.add(EducationalExp.migration)
    app.migrations.add(WorkExpIndustrySiblings.migration)
    app.migrations.add(SocialNetworkingService.migration)

    // Register routes
    try routes(app)
}

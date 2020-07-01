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

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: FileCollection.init())
    try app.register(collection: ResumeCollection.init())
    try app.register(collection: UserCollection.init())
    try app.register(collection: ExpCollection.init())
    try app.register(collection: LogCollection.init())
    try app.register(collection: SocialNetworkingServiceCollection.init())
    try app.register(collection: SocialNetworkingCollection.init())
    try app.register(collection: IndustryCollection.init())
}

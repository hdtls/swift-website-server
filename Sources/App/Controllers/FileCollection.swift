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

class FileCollection: RouteCollection {

    private let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        routes.on(.GET, "static", .parameter(restfulIDKey), use: read)
        routes.on(.GET, "images", .parameter(restfulIDKey), use: read)
    }

    /// Query md file  with name `fileID` in public fold.
    func read(_ req: Request) -> Response {

        guard let fileID = req.parameters.get(restfulIDKey) else {
            return Response.init(status: .notFound)
        }

        return req.fileio.streamFile(at: req.application.directory.publicDirectory + fileID)
    }
}

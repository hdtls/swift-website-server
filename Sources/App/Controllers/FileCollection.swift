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

import Vapor

class FileCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        routes.on(.GET, ":fileID", use: index)
    }

    func index(_ req: Request) -> Response {

        guard let fileID = req.parameters.get("fileID") else {
            return Response.init(status: .internalServerError)
        }

        return req.fileio.streamFile(at: req.application.directory.publicDirectory + fileID)
    }
}

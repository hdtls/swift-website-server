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

class ExpCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        try routes.group("exp") {
            try $0.register(collection: WorkExpCollection.init())
            try $0.register(collection: UserChildrenCollection<EducationalExp>.init(path: "edu"))
        }
    }
}

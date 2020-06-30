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

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ environment: Environment) throws -> Application {
    var environment = environment

    try LoggingSystem.bootstrap(from: &environment)

    let app = Application(environment)

    try bootstrap(app)

    return app
}

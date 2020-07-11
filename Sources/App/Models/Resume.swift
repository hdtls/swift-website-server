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

struct Resume {

    struct Module: Content {

        var id: String
        var title: String
        var profile: User.Coding?
        var works: [WorkExp.Coding]?
        var edu: [EducationalExp.Coding]?
        var skill: Skill.Coding?
        var hobbies: [String]?
    }
}

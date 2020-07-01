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

        var id: Int
        var title: String?
        var profile: User.Coding?
        var works: [JobExp]?
        var edu: [EducationalExp]?
        var hobbies: [String]?
//        var skills: [Skill]?

        init(
            id: Int,
            title: String?,
            profile: Profile? = nil,
            works: [Experience]? = nil,
            edu: [Experience]? = nil
//            hobbies: [String]? = nil,
//            skills: SkillContext? = nil
        ) {
            self.id = id
            self.title = title
            self.profile = profile
            self.works = works
            self.edu = edu
//            self.hobbies = hobbies
//            self.skills = skills
        }
    }
}

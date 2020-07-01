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

final class Skill: Model {

    typealias IDValue = UUID

    static var schema: String = "skills"

    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.profesional.rawValue)
    var profesional: [String]?

    @Field(key: FieldKeys.workflow.rawValue)
    var workflow: [String]?

    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    init() {}
}

extension Skill {

    enum FieldKeys: FieldKey {
        case profesional
        case workflow
        case user = "user_id"
    }
}

extension Skill: Transfer {

    struct Coding: Content, Equatable {

        var id: IDValue?
        var profesional: [String]?
        var workflow: [String]?
    }

    static func __converted(_ coding: Coding) throws -> Skill {
        let skill = Skill.init()
        skill.profesional = coding.profesional
        skill.workflow = coding.workflow
        return skill
    }

    func __merge(_ another: Skill) {
        profesional = another.profesional
        workflow = another.workflow
    }

    func __reverted() throws -> Coding {
        try Coding.init(id: requireID(), profesional: profesional, workflow: workflow)
    }
}

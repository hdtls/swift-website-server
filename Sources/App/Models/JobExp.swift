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

final class JobExp: Model {

    static let schema: String = "job_experiances"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.company.rawValue)
    var company: String

    @Field(key: FieldKeys.startAt.rawValue)
    var startAt: String

    @Field(key: FieldKeys.endAt.rawValue)
    var endAt: String

    @Field(key: FieldKeys.type.rawValue)
    var type: String?

    @Field(key: FieldKeys.department.rawValue)
    var department: String?

    @Field(key: FieldKeys.position.rawValue)
    var position: String?

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    // MARK: Initializer
    required init() {}
}

// MARK: Field keys
extension JobExp {

    enum FieldKeys: FieldKey {
        case user = "user_id"
        case company
        case startAt = "start_at"
        case endAt = "end_at"
        case type
        case department
        case position
    }
}

extension JobExp: UserChild {

    struct Coding: Content, Equatable {
        // MARK: Properties
        var id: JobExp.IDValue?
        var company: String
        var startAt: String
        var endAt: String
        var type: String?
        var department: String?
        var position: String?

        // MARK: Relations
        var userId: User.IDValue?
    }

    var _$user: Parent<User> {
        return $user
    }

    static func __converted(_ coding: Coding) throws -> JobExp {
        let exp = JobExp.init()
        exp.company = coding.company
        exp.startAt = coding.startAt
        exp.endAt = coding.endAt
        exp.type = coding.type
        exp.department = coding.department
        exp.position = coding.position
        return exp
    }

    func __merge(_ another: JobExp) {
        company = another.company
        startAt = another.startAt
        endAt = another.endAt
        type = another.type
        department = another.department
        position = another.position
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            company: company,
            startAt: startAt,
            endAt: endAt,
            type: type,
            department: department,
            position: position,
            userId: $user.id
        )
    }
}

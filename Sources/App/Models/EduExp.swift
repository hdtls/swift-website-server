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
import Fluent

final class EduExp: Model {

    static var schema: String = "education_experiances"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.startAt.rawValue)
    var startAt: String

    @Field(key: FieldKeys.endAt.rawValue)
    var endAt: String

    @Field(key: FieldKeys.education.rawValue)
    var education: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    // MARK: Initializer
    required init() {}

    init(
        id: EduExp.IDValue? = nil,
        userId: User.IDValue,
        startAt: String,
        endAt: String,
        education: String
    ) {
        self.id = id
        self.$user.id = userId
        self.startAt = startAt
        self.endAt = endAt
        self.education = education
    }
}

// MARK: Field keys
extension EduExp {

    enum FieldKeys: FieldKey {
        case user = "user_id"
        case startAt = "start_at"
        case endAt = "end_at"
        case education
    }
}

extension EduExp: UserChild {

    struct Coding: Content, Equatable {
        // MARK: Properties
        var id: EduExp.IDValue?
        var startAt: String
        var endAt: String
        var education: String

        // MARK: Relations
        var userId: User.IDValue?
    }

    var _$user: Parent<User> {
        return $user
    }

    static func __converted(_ coding: Coding) throws -> EduExp {
        let exp = EduExp.init()
        exp.startAt = coding.startAt
        exp.endAt = coding.endAt
        exp.education = coding.education
        return exp
    }

    func __merge(_ another: EduExp) throws {
        startAt = another.startAt
        endAt = another.endAt
        education = another.education
    }

    func __reverted() throws -> Coding {
        try Coding(
            id: requireID(),
            startAt: startAt,
            endAt: endAt,
            education: education,
            userId: $user.id
        )
    }
}

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

class EduExp: Model {

    static var schema: String = "edu_exps"

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
        id: EduExp.IDValue,
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

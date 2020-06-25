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

class JobExp: Model {

    static let schema: String = "job_exps"

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

    init(
        id: JobExp.IDValue? = nil,
        userId: User.IDValue,
        company: String,
        startAt: String,
        endAt: String,
        type: String? = nil,
        department: String? = nil,
        position: String? = nil
    ) {
        self.id = id
        self.$user.id = userId
        self.company = company
        self.startAt = startAt
        self.endAt = endAt
        self.type = type
        self.department = department
        self.position = position
    }
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

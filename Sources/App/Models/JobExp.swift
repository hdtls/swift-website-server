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

class JobExperiance: Model {

    static let schema: String = "job_exps"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "company")
    var company: String

    @Field(key: "begin_time")
    var beginTime: Date

    @Field(key: "end_time")
    var endTime: Date

    @Field(key: "type")
    var type: String

    @Field(key: "department")
    var department: String

    @Field(key: "position")
    var position: String

    @Field(key: "skills")
    var skills: String


    required init() {}
}

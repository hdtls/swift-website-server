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

final class Project: Model {
    typealias IDValue = UUID

    static var schema: String = "projects"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.name.rawValue)
    var name: String

    @Field(key: FieldKeys.categories.rawValue)
    var categories: [String]?

    @Field(key: FieldKeys.summary.rawValue)
    var summary: String

    @Field(key: FieldKeys.startDate.rawValue)
    var startDate: String

    @Field(key: FieldKeys.endDate.rawValue)
    var endDate: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    init() {}
}

// MARK: FieldKeys
extension Project {

    enum FieldKeys: FieldKey {
        case name
        case summary
        case categories
        case startDate = "start_date"
        case endDate = "end_date"
        case user = "user_id"
    }
}

extension Project: Transfer {

    struct Coding: Content, Equatable {
        var id: IDValue?
        var name: String
        var categories: [String]?
        var summary: String
        var startDate: String
        var endDate: String

        // MARK: Relations
        var userId: User.IDValue?
    }

    static func __converted(_ coding: Coding) throws -> Project {
        let proj = Project.init()
        proj.id = coding.id
        proj.name = coding.name
        proj.categories = coding.categories
        proj.summary = coding.summary
        proj.startDate = coding.startDate
        proj.endDate = coding.endDate
        return proj
    }

    func __merge(_ another: Project) {
        name = another.name
        categories = another.categories
        summary = another.summary
        startDate = another.startDate
        endDate = another.endDate
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            name: name,
            categories: categories,
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            userId: $user.id
        )
    }
}

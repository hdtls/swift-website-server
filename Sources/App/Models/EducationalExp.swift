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

final class EducationalExp: Model {

    typealias IDValue = UUID

    static var schema: String = "educational_exp"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.school.rawValue)
    var school: String

    @Field(key: FieldKeys.degree.rawValue)
    var degree: String

    @Field(key: FieldKeys.field.rawValue)
    var field: String

    @OptionalField(key: FieldKeys.startYear.rawValue)
    var startYear: String?

    @OptionalField(key: FieldKeys.endYear.rawValue)
    var endYear: String?

    @OptionalField(key: FieldKeys.grade.rawValue)
    var grade: String?

    @OptionalField(key: FieldKeys.activities.rawValue)
    var activities: [String]?

    @OptionalField(key: FieldKeys.accomplishments.rawValue)
    var accomplishments: [String]?

    @OptionalField(key: FieldKeys.media.rawValue)
    var media: String?

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    // MARK: Initializer
    init() {}
}

// MARK: Field keys
extension EducationalExp {

    enum FieldKeys: FieldKey {
        case school
        case degree
        case field = "field"
        case startYear = "start_year"
        case endYear = "end_year"
        case grade
        case activities
        case accomplishments
        case media
        case user = "user_id"
    }
}

extension EducationalExp: UserChildren {

    var _$user: Parent<User> {
        return $user
    }
    
    struct Coding: Content, Equatable {

        // MARK: Properties
        var id: IDValue?
        var school: String
        var degree: String
        var field: String
        var startYear: String?
        var endYear: String?
        var grade: String?
        var activities: [String]?
        var accomplishments: [String]?
        var media: String?

        // MARK: Relations
        var userId: User.IDValue?
    }

    static func __converted(_ coding: Coding) throws -> EducationalExp {
        let exp = EducationalExp.init()
        exp.school = coding.school
        exp.degree = coding.degree
        exp.field = coding.field
        exp.startYear = coding.startYear
        exp.endYear = coding.endYear
        exp.grade = coding.grade
        exp.activities = coding.activities
        exp.accomplishments = coding.accomplishments
        exp.media = coding.media
        return exp
    }

    func __merge(_ another: EducationalExp) {
        school = another.school
        degree = another.degree
        field = another.field
        startYear = another.startYear
        endYear = another.endYear
        grade = another.grade
        activities = another.activities
        accomplishments = another.accomplishments
        media = another.media
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            school: school,
            degree: degree,
            field: field,
            startYear: startYear,
            endYear: endYear,
            grade: grade,
            activities: activities,
            accomplishments: accomplishments,
            media: media,
            userId: $user.id
        )
    }
}

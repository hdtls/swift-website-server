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

/// Login keys defination.
protocol Credentials {
    var username: String { get set }
    var password: String { get set }
}

final class User: Model {

    static let schema: String = "users"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.username.rawValue)
    var username: String

    @Field(key: FieldKeys.pwd.rawValue)
    var pwd: String

    @Field(key: FieldKeys.firstName.rawValue)
    var firstName: String

    @Field(key: FieldKeys.lastName.rawValue)
    var lastName: String

    @Field(key: FieldKeys.screenName.rawValue)
    var screenName: String?

    @Field(key: FieldKeys.phone.rawValue)
    var phone: String?

    @Field(key: FieldKeys.emailAddress.rawValue)
    var emailAddress: String?

    @Field(key: FieldKeys.aboutMe.rawValue)
    var aboutMe: String?

    @Field(key: FieldKeys.location.rawValue)
    var location: String?

    @Timestamp(key: FieldKeys.createdAt.rawValue, on: .create)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt.rawValue, on: .update)
    var updatedAt: Date?

    // MARK: Relations
    @Children(for: \.$user)
    var tokens: [Token]

    @Children(for: \.$user)
    var social: [Social]

    @Children(for: \.$user)
    var eduExps: [EducationalExp]

    @Children(for: \.$user)
    var workExps: [WorkExp]

    // MARK: Initializer
    required init() {}

    init(
        id: User.IDValue? = nil,
        username: String,
        pwd: String,
        firstName: String,
        lastName: String,
        screenName: String? = nil,
        phone: String? = nil,
        emailAddress: String? = nil,
        aboutMe: String? = nil,
        location: String? = nil
        ) {
        self.id = id
        self.username = username
        self.pwd = pwd
        self.firstName = firstName
        self.lastName = lastName
        self.screenName = screenName
        self.phone = phone
        self.emailAddress = emailAddress
        self.aboutMe = aboutMe
        self.location = location
    }
}

// MARK: Field keys
extension User {

    enum FieldKeys: FieldKey {
        case username
        case pwd
        case firstName = "first_name"
        case lastName = "last_name"
        case screenName = "screen_name"
        case phone
        case emailAddress = "email_address"
        case aboutMe = "about_me"
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: Authentication
extension User: ModelAuthenticatable {

    static var usernameKey = \User.$username
    static var passwordHashKey = \User.$pwd

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: pwd)
    }
}

extension Validatable where Self: Credentials {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...18))
    }
}

// MARK: User creation
extension User {

    struct Creation: Credentials, Content, Validatable {
        var firstName: String
        var lastName: String
        var username: String
        var password: String
    }

    convenience init(_ creation: Creation) throws {
        self.init(
            username: creation.username,
            pwd: try Bcrypt.hash(creation.password),
            firstName: creation.firstName,
            lastName: creation.lastName
        )
    }
}

// MARK: User coding helper.
extension User: Transfer {

    /// `Coding` use for updata user and make response to user query.
    struct Coding: Content, Equatable {

        // MARK: Properties
        var id: User.IDValue?
        /// `username` is optional for decoding, required by encoding.
        /// - note: For decoding we will query default logged in user's username instead.
        var username: String?
        var firstName: String
        var lastName: String
        var screenName: String?
        var phone: String?
        var emailAddress: String?
        var aboutMe: String?
        var location: String?

        // MARK: Relations
        /// Links that user owned.
        /// - note: Only use for encoding user model.
        var social: [Social.Coding]?

        /// Education experiances
        /// - seealso: `Coding.webLinks`
        var eduExps: [EducationalExp.Coding]?

        /// Jon experiances
        /// - seealso: `Coding.webLinks`
        var workExps: [WorkExp.Coding]?
    }

    static func __converted(_ coding: Coding) throws -> User {
        let user = User.init()
        user.firstName = coding.firstName
        user.lastName = coding.lastName
        user.screenName = coding.screenName
        user.phone = coding.phone
        user.emailAddress = coding.emailAddress
        user.aboutMe = coding.aboutMe
        user.location = coding.location
        return user
    }

    func __merge(_ user: User) {
        firstName = user.firstName
        lastName = user.lastName
        screenName = user.screenName
        phone = user.phone
        emailAddress = user.emailAddress
        aboutMe = user.aboutMe
        location = user.location
    }
    
    func __reverted() throws -> Coding {
        var coding = Coding.init(firstName: firstName, lastName: lastName)
        coding.id = try requireID()
        coding.username = username
        coding.screenName = screenName
        coding.phone = phone
        coding.emailAddress = emailAddress
        coding.aboutMe = aboutMe
        coding.location = location
        coding.social = $social.value?.compactMap({ try? $0.__reverted() })
        coding.eduExps = $eduExps.value?.compactMap({ try? $0.__reverted() })
        coding.workExps = $workExps.value?.compactMap({ try? $0.__reverted() })
        coding.social = $social.value?.compactMap({ try? $0.__reverted() })
        return coding
    }
}

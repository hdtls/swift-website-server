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

protocol UserOpenJSONProperties {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue? { get set }
    var username: String { get set }
    var phone: String? { get set }
    var emailAddress: String? { get set }
    var description: String? { get set }
}

final class User: Model, UserOpenJSONProperties {

    static let schema: String = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "pwd")
    var pwd: String

    @Field(key: "name")
    var name: String?

    @Field(key: "screen_name")
    var screenName: String?

    @Field(key: "phone")
    var phone: String?

    @Field(key: "email_address")
    var emailAddress: String?

    @Field(key: "description")
    var description: String?

    @Field(key: "location")
    var location: String?

    @Field(key: "profile_background_color")
    var profileBackgroundColor: String?

    @Field(key: "profile_background_image_url")
    var profileBackgroundImageUrl: String?

    @Field(key: "profile_background_tile")
    var profileBackgroundTile: String?

    @Field(key: "profile_image_url")
    var profileImageUrl: String?

    @Field(key: "profile_banner_url")
    var profileBannerUrl: String?

    @Field(key: "profile_link_color")
    var profileLinkColor: String?

    @Field(key: "profile_text_color")
    var profileTextColor: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    required init() {}

    init(
        id: User.IDValue? = nil,
        username: String,
        pwd: String,
        phone: String? = nil,
        emailAddress: String? = nil,
        description: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.username = username
        self.pwd = pwd
        self.phone = phone
        self.emailAddress = emailAddress
        self.description = description
        self.location = location
        self.createdAt = nil
        self.updatedAt = nil
    }
}

extension User: ModelAuthenticatable {

    static var usernameKey = \User.$username
    static var passwordHashKey = \User.$pwd

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: pwd)
    }
}

/// Login keys defination.
protocol Credentials {
    var username: String { get set }
    var password: String { get set }
}

extension Validatable where Self: Credentials {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

/// User registration
extension User {

    struct Registration: Credentials, Content, Validatable {
        var username: String
        var password: String
    }

    convenience init(_ registration: Registration) throws {
        self.init(username: registration.username, pwd: try Bcrypt.hash(registration.password))
    }
}

/// User readable properties defination.
extension User {
    struct Body: UserOpenJSONProperties, Content {

        typealias IDValue = User.IDValue

        var id: IDValue?
        var username: String
        var phone: String?
        var emailAddress: String?
        var description: String?

        init(_ user: User) {
            id = user.id
            username = user.username
            phone = user.phone
            emailAddress = user.emailAddress
            description = user.description
        }
    }
}


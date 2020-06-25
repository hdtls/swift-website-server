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

/// Login keys defination.
protocol Credentials {
    var username: String { get set }
    var password: String { get set }
}

protocol UserOpenJSONProperties {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue? { get set }
    var username: String { get set }
    var phone: String? { get set }
    var emailAddress: String? { get set }
    var aboutMe: String? { get set }
}

final class User: Model, UserOpenJSONProperties {

    static let schema: String = "users"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.username.rawValue)
    var username: String

    @Field(key: FieldKeys.pwd.rawValue)
    var pwd: String

    @Field(key: FieldKeys.name.rawValue)
    var name: String?

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

    @Field(key: FieldKeys.profileBackgroundColor.rawValue)
    var profileBackgroundColor: String?

    @Field(key: FieldKeys.profileBackgroundImageUrl.rawValue)
    var profileBackgroundImageUrl: String?

    @Field(key: FieldKeys.profileBackgroundTile.rawValue)
    var profileBackgroundTile: String?

    @Field(key: FieldKeys.profileImageUrl.rawValue)
    var profileImageUrl: String?

    @Field(key: FieldKeys.profileBannerUrl.rawValue)
    var profileBannerUrl: String?

    @Field(key: FieldKeys.profileLinkColor.rawValue)
    var profileLinkColor: String?

    @Field(key: FieldKeys.profileTextColor.rawValue)
    var profileTextColor: String?

    @Timestamp(key: FieldKeys.createdAt.rawValue, on: .create)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt.rawValue, on: .update)
    var updatedAt: Date?

    // MARK: Relations
    @Children(for: \.$user)
    var tokens: [Token]

    @Children(for: \.$user)
    var webLinks: [WebLink]

    @Children(for: \.$user)
    var eduExps: [EduExp]

    @Children(for: \.$user)
    var jobExps: [JobExp]

    // MARK: Initializer
    required init() {}

    init(
        id: User.IDValue? = nil,
        username: String,
        pwd: String,
        screenName: String? = nil,
        phone: String? = nil,
        emailAddress: String? = nil,
        aboutMe: String? = nil,
        location: String? = nil,
        profileBackgroundColor: String? = nil,
        profileBackgroundImageUrl: String? = nil,
        profileBackgroundTile: String? = nil,
        profileImageUrl: String? = nil,
        profileBannerUrl: String? = nil,
        profileLinkColor: String? = nil,
        profileTextColor: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
        ) {
        self.id = id
        self.username = username
        self.pwd = pwd
        self.screenName = screenName
        self.phone = phone
        self.emailAddress = emailAddress
        self.aboutMe = aboutMe
        self.location = location
        self.profileBackgroundColor = profileBackgroundColor
        self.profileBackgroundImageUrl = profileBackgroundImageUrl
        self.profileBackgroundTile = profileBackgroundTile
        self.profileImageUrl = profileImageUrl
        self.profileBannerUrl = profileBannerUrl
        self.profileLinkColor = profileLinkColor
        self.profileTextColor = profileTextColor
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: Field keys
extension User {

    enum FieldKeys: FieldKey {
        case username
        case pwd
        case name
        case screenName = "screen_name"
        case phone
        case emailAddress = "email_address"
        case aboutMe = "about_me"
        case location
        case profileBackgroundColor = "profile_background_color"
        case profileBackgroundImageUrl = "profile_background_image_url"
        case profileBackgroundTile = "profile_background_tile"
        case profileImageUrl = "profile_image_url"
        case profileBannerUrl = "profile_banner_url"
        case profileLinkColor = "profile_link_color"
        case profileTextColor = "profile_text_color"
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
        validations.add("password", as: String.self, is: .count(6...))
    }
}

// MARK: User registration
extension User {

    struct Registration: Credentials, Content, Validatable {
        var username: String
        var password: String
    }

    convenience init(_ registration: Registration) throws {
        self.init(username: registration.username, pwd: try Bcrypt.hash(registration.password))
    }
}

// MARK: User public properties defination.
extension User {
    struct Body: UserOpenJSONProperties, Content {

        typealias IDValue = User.IDValue

        var id: IDValue?
        var username: String
        var phone: String?
        var emailAddress: String?
        var aboutMe: String?

        init(_ user: User) {
            id = user.id
            username = user.username
            phone = user.phone
            emailAddress = user.emailAddress
            aboutMe = user.aboutMe
        }
    }
}

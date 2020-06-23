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
}

final class User: Model, UserOpenJSONProperties {

    static let schema: String = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "pwd_hash")
    var pwdhash: String

    required init() {}

    init(id: UUID? = nil, username: String, pwdhash: String) {
        self.id = id
        self.username = username
        self.pwdhash = pwdhash
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> {
        \User.$username
    }

    static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$pwdhash
    }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.pwdhash)
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
        self.init(username: registration.username, pwdhash: try Bcrypt.hash(registration.password))
    }
}

/// User readable properties defination.
extension User {
    struct Body: UserOpenJSONProperties, Content {
        typealias IDValue = User.IDValue

        var id: IDValue?
        var username: String

        init(_ user: User) {
            id = user.id
            username = user.username
        }
    }
}


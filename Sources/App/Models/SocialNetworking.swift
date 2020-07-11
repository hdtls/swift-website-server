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

final class SocialNetworking: Model {

    static var schema: String = "social_networking"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.url.rawValue)
    var url: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    @Parent(key: FieldKeys.service.rawValue)
    var service: Service

    // MARK: Initializer
    required init() {}
}

// MARK: Field keys
extension SocialNetworking {

    enum FieldKeys: FieldKey {
        case user = "user_id"
        case url
        case service = "service_id"
    }
}

extension SocialNetworking: UserChildren {

    var _$user: Parent<User> {
        return $user
    }

    struct Coding: Content, Equatable {
        var id: SocialNetworking.IDValue?
        var userId: User.IDValue?
        var url: String

        /// `ID` of `service` is require for create referance with `SocialNetworkingService`
        var service: Service.Coding?
    }

    static func __converted(_ coding: Coding) throws -> SocialNetworking {
        guard let serviceID = coding.service?.id else {
            throw Abort.init(.badRequest, reason: "Value required for key 'service.id'")
        }
        let social = SocialNetworking.init()
        social.url = coding.url
        social.$service.id = serviceID
        return social
    }

    // Only `url` property can be update.
    func __merge(_ another: SocialNetworking) {
        url = another.url
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            userId: $user.id,
            url: url,
            service: service.__reverted()
        )
    }
}

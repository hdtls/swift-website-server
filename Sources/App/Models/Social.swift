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

final class Social: Model {

    static var schema: String = "social"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.url.rawValue)
    var url: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    @Parent(key: FieldKeys.networkingService.rawValue)
    var networkingService: SocialNetworkingService

    // MARK: Initializer
    required init() {}
}

// MARK: Field keys
extension Social {

    enum FieldKeys: FieldKey {
        case user = "user_id"
        case url
        case networkingService = "networking_service_id"
    }
}

extension Social: UserChild {

    var _$user: Parent<User> {
        $user
    }

    struct Coding: Content, Equatable {
        var id: Social.IDValue?
        var userId: User.IDValue?
        var url: String

        /// `ID` of `networkingService` is require for create referance with `SocialNetworkingService`
        /// This property only used for decoding. ignore by encoding.
        var networkingServiceId: SocialNetworkingService.IDValue?
        var networkingService: SocialNetworkingService.Coding?
    }

    static func __converted(_ coding: Coding) throws -> Social {
        guard let serviceID = coding.networkingServiceId else {
            throw Abort.init(.badRequest, reason: "Value required for key 'socialNetworkingService.id'")
        }
        let social = Social.init()
        social.url = coding.url
        social.$networkingService.id = serviceID
        return social
    }

    // Only `url` property can be update.
    func __merge(_ another: Social) {
        url = another.url
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            userId: $user.id,
            url: url,
            networkingService: networkingService.__reverted()
        )
    }
}

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

class SocialMedia: Model {

    static var schema: String = "social_medias"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Enum(key: FieldKeys.type.rawValue)
    var type: MediaType

    // MARK: Relations
    @Siblings(through: WebLinkSocialMediaSiblings.self, from: \.$socialMedia, to: \.$webLink)
    var webLinkOwners: [WebLink]

    // MARK: Initializer
    required init() {}

    init(id: SocialMedia.IDValue? = nil, type: SocialMedia.MediaType) {
        self.id = id
        self.type = type
    }
}

// MARK: Field keys
extension SocialMedia {

    enum FieldKeys: FieldKey {
        case type
    }
}

// MARK: Meida tpye defination
extension SocialMedia {

    enum MediaType: String, Codable, CaseIterable {
        static var name: FieldKey = "social_media_type"
        case twitter
        case facebook
        case githup
        case stackOverflow
        case wechat
        case qq
        case mail
        case website
    }
}

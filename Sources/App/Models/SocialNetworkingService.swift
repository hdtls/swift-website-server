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

final class SocialNetworkingService: Model {

    static var schema: String = "social_networking_services"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Enum(key: FieldKeys.type.rawValue)
    var type: ServiceType

    @Field(key: FieldKeys.imageUrl.rawValue)
    var imageUrl: String?

    @Field(key: FieldKeys.html.rawValue)
    var html: String?

    // MARK: Relations
    @Children(for: \.$networkingService)
    var social: [Social]

    // MARK: Initializer
    required init() {}
}

// MARK: Field keys
extension SocialNetworkingService {

    enum FieldKeys: FieldKey {
        case type
        case imageUrl = "image_url"
        case html
    }
}

// MARK: Meida tpye defination
extension SocialNetworkingService {

    enum ServiceType: String, CaseIterable, Codable {

        case facebook = "Facebook"
        case youTube = "YouTube"
        case twitter = "Twitter"
        case whatsApp = "WhatsApp"
        case messenger = "Facebook Messenger"
        case wechat = "WeChat"
        case instagram = "Instagram"
        case tikTok = "TikTok"
        case qq = "QQ"
        case qzone = "Qzone"
        case weibo = "Sina Weibo"
        case reddit = "Reddit"
        case kuaishou = "Kuaishou"
        case snapchat = "Snapchat"
        case pinterest = "Pinterest"
        case tieba = "Baidu Tieba"
        case linkedIn = "LinkedIn"
        case viber = "Viber"
        case discord = "Discord"
        case githup = "Github"
        case stackOverflow = "StackOverflow"
        case mail = "Mail"
        case website = "Website"
        case undefine
    }
}

extension SocialNetworkingService: Transfer {

    struct Coding: Content, Equatable {
        var id: SocialNetworkingService.IDValue?
        var type: SocialNetworkingService.ServiceType
        var imageUrl: String?
        var html: String?
    }

    static func __converted(_ coding: Coding) throws -> SocialNetworkingService {
        let social = SocialNetworkingService.init()
        social.type = coding.type
        social.imageUrl = coding.imageUrl
        social.html = coding.html
        return social
    }

    func __merge(_ another: SocialNetworkingService) {
        type = another.type
        imageUrl = another.imageUrl
        html = another.html
    }

    func __reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            type: type,
            imageUrl: imageUrl,
            html: html
        )
    }
}

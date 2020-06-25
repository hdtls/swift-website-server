//
//  File.swift
//  
//
//  Created by melvyn on 6/25/20.
//

import Vapor
import Fluent

class WebLinkSocialMediaSiblings: Model {

    static var schema: String = "web_link_social_media_siblings"

    // MARK: Properties
    @ID()
    var id: UUID?

    // MARK: Relations
    @Parent(key: FieldKeys.webLink.rawValue)
    var webLink: WebLink

    @Parent(key: FieldKeys.socialMedia.rawValue)
    var socialMedia: SocialMedia

    // MARK: Initializer
    required init() {}

    init(id: WebLinkSocialMediaSiblings.IDValue? = nil, webLink: WebLink.IDValue, socialMedia: SocialMedia.IDValue) {
        self.id = id
        self.$webLink.id = webLink
        self.$socialMedia.id = socialMedia
    }
}

// MARK: Field keys
extension WebLinkSocialMediaSiblings {

    enum FieldKeys: FieldKey, CaseIterable {
        case id
        case webLink = "web_link_id"
        case socialMedia = "social_media_id"
    }
}

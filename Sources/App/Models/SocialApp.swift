//
//  SocialApp.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor

struct SocialApp: Codable {

    var title: String?
    var href: String?
    var icon: SVG?

    init(title: String?, href: String?, icon: SVG?) {
        self.title = title
        self.href = href
        self.icon = icon
    }
}

extension SocialApp: Content {}

//
//  Exp.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor

struct Experience: Codable {
    var title: String?
    var responsibility: String?
    var time: String?
    var description: String?
}

extension Experience: Content {}

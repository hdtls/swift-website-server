
//
//  File.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor

struct Skill: Codable {
    var title: String?
    var description: String?
    var icon: SVG?
}

extension Skill: Content {}

struct SkillContext: Codable {

    var langAndDevTools: [Skill]?
    var workflow: [String]?
}

extension SkillContext: Content {}

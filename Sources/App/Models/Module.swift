//
//  Module.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor

struct Module: Codable {

    var id: Int

    var title: String?
    var profile: Profile?
    var works: [Experience]?
    var edu: [Experience]?
    var hobbies: [String]?
    var skills: SkillContext?

    init(
        id: Int,
        title: String?,
        profile: Profile? = nil,
        works: [Experience]? = nil,
        edu: [Experience]? = nil,
        hobbies: [String]? = nil,
        skills: SkillContext? = nil
    ) {
        self.id = id
        self.title = title
        self.profile = profile
        self.works = works
        self.edu = edu
        self.hobbies = hobbies
        self.skills = skills
    }
}

extension Module: Content {}

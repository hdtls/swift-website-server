import Vapor

struct Resume {

    struct Module: Content {

        var id: String
        var title: String
        var profile: User.Coding?
        var works: [WorkExp.Coding]?
        var edu: [EducationalExp.Coding]?
        var skill: Skill.Coding?
        var hobbies: [String]?
    }
}

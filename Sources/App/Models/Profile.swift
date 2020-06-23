//
//  Profile.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor
import Fluent

struct Profile: Codable {

//    @ID(key: .id)
    var id: Int?

//    @Field(key: "first_name")
    var firstName: String?
    var lastName: String?
    var address: String?
    var phone: String?
    var email: String?
    var intro: String?
    var socialApps: [SocialApp]?

    init(
        firstName: String? = nil,
        lastName: String? = nil,
        address: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        intro: String? = nil,
        socialApps: [SocialApp]? = nil
        ) {
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.phone = phone
        self.email = email
        self.intro = intro
        self.socialApps = socialApps
    }

    init() {
        self.init(firstName: nil, lastName: nil, address: nil, phone: nil, email: nil, intro: nil, socialApps: nil)
    }
}

extension Profile {
//    struct Field {
//        let firstName = "first_name"
//        let lastName = "last_name"
//        let address = "address"
//        let phone = "phone"
//        let email = "email"
//        let intro = "intro"
//        let socialApps = "social_apps"
//    }
}

extension Profile: Content {}

//extension Profile: Model {
//
//    static var schema: String {
//        "profiles"
//    }
//}

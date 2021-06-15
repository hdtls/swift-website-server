import XCTVapor
@testable import App

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map({ _ in letters.randomElement()! }))
    }
}

extension User.Creation {
    static func generate() -> User.Creation {
        .init(firstName: .random(length: 6), lastName: .random(length: 7), username: .random(length: 8), password: .random(length: 9))
    }
}

extension Experience.DTO {
    static func generate() -> Experience.DTO {
        var expected = Experience.DTO.init()
        expected.id = .init()
        expected.title = .random(length: 4)
        expected.companyName = .random(length: 6)
        expected.location = .random(length: 5)
        expected.startDate = .random(length: 5)
        expected.endDate = .random(length: 5)
        expected.headline = nil
        expected.responsibilities = [.random(length: 8)]
        expected.media = nil
        expected.industries = []
        expected.userId = nil
        return expected
    }
}

extension Industry.DTO {
    static func generate() -> Industry.DTO {
        var expected = Industry.DTO.init()
        expected.id = .init()
        expected.title = .random(length: 6)
        return expected
    }
}

extension Education.DTO {
    static func generate() -> Education.DTO {
        var expected = Education.DTO.init()
        expected.id = .init()
        expected.school = .random(length: 12)
        expected.degree = .random(length: 4)
        expected.field = .random(length: 7)
        expected.startYear = .random(length: 3)
        expected.endYear = .random(length: 6)
        expected.grade = .random(length: 5)
        expected.activities = [.random(length: 9)]
        expected.accomplishments = [.random(length: 12), .random(length: 10)]
        expected.media = nil
        expected.userId = nil
        return expected
    }
}

extension SocialNetworkingService.DTO {
    static func generate() -> SocialNetworkingService.DTO {
        var expected = SocialNetworkingService.DTO.init()
        expected.id = .init()
        expected.type = SocialNetworkingService.ServiceType.allCases.randomElement()
        return expected
    }
}

extension SocialNetworking.DTO {
    static func generate() -> SocialNetworking.DTO {
        var expected = SocialNetworking.DTO.init()
        expected.id = .init()
        expected.url = .random(length: 12)
        return expected
    }
}

extension Project.DTO {
    static func generate() -> Project.DTO {
        var expected = Project.DTO.init()
        expected.id = .init()
        expected.artworkUrl = "http://localhost:8080/" + .random(length: 12)
        expected.endDate = .random(length: 7)
        expected.startDate = .random(length: 7)
        expected.genres = [.random(length: 4)]
        expected.kind = .allCases.randomElement()!
        expected.name = .random(length: 8)
        expected.summary = .random(length: 24)
        expected.visibility = .allCases.randomElement()!
        return expected
    }
}

extension BlogCategory.DTO {
    static func generate() -> BlogCategory.DTO {
        var expected = BlogCategory.DTO.init()
        expected.id = .init()
        expected.name = .random(length: 6)
        return expected
    }
}

extension Blog.DTO {
    static func generate() -> Blog.DTO {
        var expected = Blog.DTO.init()
        expected.id = .init()
        expected.alias = .random(length: 12)
        expected.title = .random(length: 12)
        expected.excerpt = .random(length: 23)
        expected.content = .random(length: 32)
        expected.categories = []
        return expected
    }
}

extension Skill.DTO {
    static func generate() -> Skill.DTO {
        var expected = Skill.DTO.init()
        expected.id = .init()
        expected.professional = [.random(length: 14)]
        expected.workflow = [.random(length: 24)]
        return expected
    }
}


func assertHttpUnauthorized(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .unauthorized)
}

func assertHttpOk(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .ok)
}

func assertHttpNotFound(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .notFound)
}

func assertHttpServerError(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .internalServerError)
}

func assertHttpBadRequest(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .badRequest)
}

func assertHttpUnprocessableEntity(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .unprocessableEntity)
}


extension Application {
    
    struct LoggedInMsg {
        let registration: User.Creation
        let user: User.DTO
        let headers: HTTPHeaders
    }
        
    struct Storage {
        var blogCategory: BlogCategory.DTO?
        var blog: Blog.DTO?
        var experience: Experience.DTO?
        var education: Education.DTO?
        var industry: Industry.DTO?
        var socialNetworking: SocialNetworking.DTO?
        var socialNetworkingService: SocialNetworkingService.DTO?
        var project: Project.DTO?
        var skill: Skill.DTO?
        var user: User.DTO?
        var loggedInMsg: LoggedInMsg?
    }
    
    static var meta: Storage = .init()
    
    @discardableResult
    func registerUserWithLegacy(_ registration: User.Creation? = nil) -> User.DTO {
        guard registration != nil || Self.meta.user == nil else {
            return Self.meta.user!
        }
        
        let codable = registration ?? .generate()
        var user = User.DTO.init()
        XCTAssertNoThrow(
            try test(.POST, User.schema, beforeRequest: {
                try $0.content.encode(codable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                
                user = try $0.content.decode(User.DTO.self)
                XCTAssertNotNil(user)
                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, codable.username)
                XCTAssertEqual(user.firstName, codable.firstName)
                XCTAssertEqual(user.lastName, codable.lastName)
                XCTAssertNil(user.phone)
                XCTAssertNil(user.emailAddress)
                XCTAssertNil(user.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertNil(user.education)
                XCTAssertNil(user.experiences)
                XCTAssertNil(user.interests)
                                
                if Self.meta.user == nil {
                    Self.meta.user = user
                }
            })
        )
        
        return user
    }
    
    func login() -> LoggedInMsg {
        
        guard Self.meta.loggedInMsg == nil else {
            return Self.meta.loggedInMsg!
        }
        
        let registration = User.Creation.generate()
        let user = registerUserWithLegacy(registration)
        
        let credentials = "\(registration.username):\(registration.password)".data(using: .utf8)!.base64EncodedString()
        
        let headers = HTTPHeaders.init([("Authorization", "Basic \(credentials)")])
        
        var identityTokenString = ""
        
        XCTAssertNoThrow(
            try test(.POST, "authorize/basic", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                identityTokenString = try $0.content.decode(AuthorizedMsg.self).identityTokenString
            })
        )
        
        Self.meta.loggedInMsg = .init(
            registration: registration,
            user: user,
            headers: .init([("Authorization", "Bearer " + identityTokenString)])
        )
        return Self.meta.loggedInMsg!
    }
    
    func logout() throws {
        guard let loggedInMsg = Self.meta.loggedInMsg else {
            return
        }
        
        XCTAssertNoThrow(
            try test(.DELETE, "unauthorized", headers: loggedInMsg.headers, afterResponse: assertHttpOk)
        )
        
        Self.meta.loggedInMsg = nil
    }
    
    @discardableResult
    func requestBlogCategory(_ data: BlogCategory.DTO? = nil) -> BlogCategory.DTO {
        
        guard data != nil || Self.meta.blogCategory == nil else {
            return Self.meta.blogCategory!
        }
        let encodable = data ?? BlogCategory.DTO.generate()
        var model: BlogCategory.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, BlogCategory.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(encodable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(BlogCategory.DTO.self)
                XCTAssertEqual(model.name, encodable.name)
                if Self.meta.blogCategory == nil {
                    Self.meta.blogCategory = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestBlog(_ data: Blog.DTO? = nil) -> Blog.DTO {
        guard data != nil || Self.meta.blog == nil else {
            return Self.meta.blog!
        }
        var encodable = data ?? Blog.DTO.generate()
        if data == nil {
            encodable.categories = [requestBlogCategory()]
        }
        var model: Blog.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Blog.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(encodable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Blog.DTO.self)
                
                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.alias, encodable.alias)
                XCTAssertEqual(model.title, encodable.title)
                XCTAssertEqual(model.artworkUrl, encodable.artworkUrl)
                XCTAssertEqual(model.excerpt, encodable.excerpt)
                XCTAssertEqual(model.tags, encodable.tags)
                XCTAssertEqual(model.content, encodable.content)
                XCTAssertEqual(model.categories.count, encodable.categories.count)
                if Self.meta.blog == nil {
                    Self.meta.blog = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestIndustry(_ data: Industry.DTO? = nil) -> Industry.DTO {
        guard data != nil || Self.meta.industry == nil else {
            return Self.meta.industry!
        }
        let expected = data ?? Industry.DTO.generate()
        var model: Industry.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Industry.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Industry.DTO.self)
                XCTAssertNotNil(model.id)
                XCTAssertEqual(model.title, expected.title)
                
                if Self.meta.industry == nil {
                    Self.meta.industry = model
                }
            })
        )
        return model
    }
    
    @discardableResult
    func requestJobExperience(_ data: Experience.DTO? = nil) -> Experience.DTO {
        
        guard data != nil || Self.meta.experience == nil else {
            return Self.meta.experience!
        }
        var expected = data ?? Experience.DTO.generate()
        if data == nil {
            expected.industries = [requestIndustry()]
        }
        var model: Experience.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Experience.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Experience.DTO.self)
                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.title, expected.title)
                XCTAssertEqual(model.companyName, expected.companyName)
                XCTAssertEqual(model.location, expected.location)
                XCTAssertEqual(model.startDate, expected.startDate)
                XCTAssertEqual(model.endDate, expected.endDate)
                XCTAssertEqual(model.industries.first?.id, expected.industries.first?.id)
                XCTAssertEqual(model.industries.first?.title, expected.industries.first?.title)
                XCTAssertEqual(model.headline, expected.headline)
                XCTAssertEqual(model.responsibilities, expected.responsibilities)
                if Self.meta.experience == nil {
                    Self.meta.experience = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestEducation(_ data: Education.DTO? = nil) -> Education.DTO {
        guard data != nil || Self.meta.education == nil else {
            return Self.meta.education!
        }
        var expected = data ?? Education.DTO.generate()
        expected.userId = login().user.id
        var model: Education.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Education.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Education.DTO.self)
                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.school, expected.school)
                XCTAssertEqual(model.degree, expected.degree)
                XCTAssertEqual(model.field, expected.field)
                XCTAssertEqual(model.startYear, expected.startYear)
                XCTAssertEqual(model.endYear, expected.endYear)
                XCTAssertEqual(model.activities, expected.activities)
                XCTAssertEqual(model.accomplishments, expected.accomplishments)
                
                if Self.meta.education == nil {
                    Self.meta.education = model
                }
            })
        )
        return model
    }
    
    @discardableResult
    func requestSocialNetworkingService(_ data: SocialNetworkingService.DTO? = nil) -> SocialNetworkingService.DTO {
        guard data != nil || Self.meta.socialNetworkingService == nil else {
            return Self.meta.socialNetworkingService!
        }
        let expected = data ?? SocialNetworkingService.DTO.generate()
        var model: SocialNetworkingService.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, SocialNetworking.schema + "/services", headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(SocialNetworkingService.DTO.self)
                XCTAssertNotNil(model.id)
                XCTAssertEqual(model.type, expected.type)
                
                if Self.meta.socialNetworkingService == nil {
                    Self.meta.socialNetworkingService = model
                }
            })
        )
        return model
    }
    
    @discardableResult
    func requestSocialNetworking(_ data: SocialNetworking.DTO? = nil) -> SocialNetworking.DTO {
        guard data != nil || Self.meta.socialNetworking == nil else {
            return Self.meta.socialNetworking!
        }
        var expected = data ?? SocialNetworking.DTO.generate()
        
        if data == nil {
            expected.serviceId = requestSocialNetworkingService().id
        }
        
        var model: SocialNetworking.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, SocialNetworking.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(SocialNetworking.DTO.self)

                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.url, expected.url)
                XCTAssertNotNil(model.service)
                XCTAssertEqual(model.service?.id, expected.serviceId)
                
                if Self.meta.socialNetworking == nil {
                    Self.meta.socialNetworking = model
                }
            })
        )
        return model

    }
    
    @discardableResult
    func requestProject(_ data: Project.DTO? = nil) -> Project.DTO {
        
        guard data != nil || Self.meta.project == nil else {
            return Self.meta.project!
        }
        let expected = data ?? Project.DTO.generate()
        
        var model: Project.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Project.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)

                model = try $0.content.decode(Project.Coding.self)
                XCTAssertNotNil(model.id)
                XCTAssertEqual(model.name, expected.name)
                XCTAssertEqual(model.note, expected.note)
                XCTAssertEqual(model.genres, expected.genres)
                XCTAssertEqual(model.summary, expected.summary)
                XCTAssertEqual(model.artworkUrl, expected.artworkUrl)
                XCTAssertEqual(model.backgroundImageUrl, expected.backgroundImageUrl)
                XCTAssertEqual(model.promoImageUrl, expected.promoImageUrl)
                XCTAssertEqual(model.screenshotUrls, expected.screenshotUrls)
                XCTAssertEqual(model.padScreenshotUrls, expected.padScreenshotUrls)
                XCTAssertEqual(model.kind, expected.kind)
                XCTAssertEqual(model.visibility, expected.visibility)
                XCTAssertEqual(model.trackViewUrl, expected.trackViewUrl)
                XCTAssertEqual(model.trackId, expected.trackId)
                XCTAssertEqual(model.startDate, expected.startDate)
                XCTAssertEqual(model.endDate, expected.endDate)
                XCTAssertNotNil(model.userId)
                
                if Self.meta.project == nil {
                    Self.meta.project = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestSkill(_ data: Skill.DTO? = nil) -> Skill.DTO {
        guard data != nil || Self.meta.skill == nil else {
            return Self.meta.skill!
        }
        let expected = data ?? Skill.DTO.generate()
        
        var model: Skill.DTO = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Skill.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                
                model = try $0.content.decode(Skill.DTO.self)

                XCTAssertNotNil(model.id)
                XCTAssertEqual(model.professional, expected.professional)
                XCTAssertEqual(model.workflow, expected.workflow)
                
                if Self.meta.skill == nil {
                    Self.meta.skill = model
                }
            })
        )
        
        return model
    }
}

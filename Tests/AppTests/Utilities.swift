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

extension Experience.SerializedObject {
    static func generate() -> Experience.SerializedObject {
        var expected = Experience.SerializedObject.init()
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

extension Industry.SerializedObject {
    static func generate() -> Industry.SerializedObject {
        var expected = Industry.SerializedObject.init()
        expected.title = .random(length: 6)
        return expected
    }
}

extension Education.SerializedObject {
    static func generate() -> Education.SerializedObject {
        var expected = Education.SerializedObject.init()
        expected.id = nil
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

extension SocialNetworkingService.SerializedObject {
    static func generate() -> SocialNetworkingService.SerializedObject {
        var expected = SocialNetworkingService.SerializedObject.init()
        expected.type = SocialNetworkingService.ServiceType.allCases.randomElement()
        return expected
    }
}

extension SocialNetworking.SerializedObject {
    static func generate() -> SocialNetworking.SerializedObject {
        var expected = SocialNetworking.SerializedObject.init()
        expected.url = .random(length: 12)
        return expected
    }
}

extension Project.SerializedObject {
    static func generate() -> Project.SerializedObject {
        var expected = Project.SerializedObject.init()
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

extension BlogCategory {
    static func generate() -> BlogCategory {
        let blogCategory = BlogCategory.init()
        blogCategory.name = .random(length: 6)
        return blogCategory
    }
}

extension Blog.SerializedObject {
    static func generate() -> Blog.SerializedObject {
        var expected = Blog.SerializedObject.init()
        expected.alias = .random(length: 12)
        expected.title = .random(length: 12)
        expected.excerpt = .random(length: 23)
        expected.content = .random(length: 32)
        expected.categories = []
        return expected
    }
}

extension Skill.SerializedObject {
    static func generate() -> Skill.SerializedObject {
        var expected = Skill.SerializedObject.init()
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


extension Application {
    
    struct LoggedInMsg {
        let registration: User.Creation
        let user: User.SerializedObject
        let headers: HTTPHeaders
    }
        
    struct Storage {
        var user: User.SerializedObject?
        var blogCategory: BlogCategory.SerializedObject?
        var blog: Blog.SerializedObject?
        var experience: Experience.SerializedObject?
        var education: Education.SerializedObject?
        var industry: Industry.SerializedObject?
        var socialNetworking: SocialNetworking.SerializedObject?
        var socialNetworkingService: SocialNetworkingService.SerializedObject?
        var project: Project.SerializedObject?
        var skill: Skill.SerializedObject?
        var loggedInMsg: LoggedInMsg?
    }
    
    static var meta: Storage = .init()
    
    @discardableResult
    func registerUserWithLegacy(_ registration: User.Creation? = nil) -> User.SerializedObject {
        guard registration != nil || Self.meta.user == nil else {
            return Self.meta.user!
        }
        
        let codable = registration ?? .generate()
        var user = User.SerializedObject.init()
        XCTAssertNoThrow(
            try test(.POST, User.schema, beforeRequest: {
                try $0.content.encode(codable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                
                let authorizeMsg = try $0.content.decode(AuthorizeMsg.self)
                XCTAssertNotNil(authorizeMsg.accessToken)
                XCTAssertNotNil(authorizeMsg.user)
                XCTAssertNotNil(authorizeMsg.user.id)
                XCTAssertEqual(authorizeMsg.user.username, registration?.username)
                XCTAssertEqual(authorizeMsg.user.firstName, registration?.firstName)
                XCTAssertEqual(authorizeMsg.user.lastName, registration?.lastName)
                XCTAssertNil(authorizeMsg.user.phone)
                XCTAssertNil(authorizeMsg.user.emailAddress)
                XCTAssertNil(authorizeMsg.user.aboutMe)
                XCTAssertNil(authorizeMsg.user.location)
                XCTAssertNil(authorizeMsg.user.education)
                XCTAssertNil(authorizeMsg.user.experiences)
                XCTAssertNil(authorizeMsg.user.interests)
                
                user = authorizeMsg.user
                
                if Self.meta.user == nil {
                    Self.meta.user = authorizeMsg.user
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
            try test(.POST, "login", headers: headers, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                identityTokenString = try $0.content.decode(AuthorizeMsg.self).accessToken
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
            try test(.POST, "logout", headers: loggedInMsg.headers, afterResponse: assertHttpOk)
        )
        
        Self.meta.loggedInMsg = nil
    }
    
    @discardableResult
    func requestBlogCategory(_ data: BlogCategory.SerializedObject? = nil) -> BlogCategory.SerializedObject {
        
        guard data != nil || Self.meta.blogCategory == nil else {
            return Self.meta.blogCategory!
        }
        let encodable = data ?? BlogCategory.SerializedObject.generate()
        var model: BlogCategory.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, BlogCategory.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(encodable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(BlogCategory.SerializedObject.self)
                XCTAssertEqual(model.name, encodable.name)
                if Self.meta.blogCategory == nil {
                    Self.meta.blogCategory = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestBlog(_ data: Blog.SerializedObject? = nil) -> Blog.SerializedObject {
        guard data != nil || Self.meta.blog == nil else {
            return Self.meta.blog!
        }
        var encodable = data ?? Blog.SerializedObject.generate()
        if data == nil {
            encodable.categories = [requestBlogCategory()]
        }
        var model: Blog.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Blog.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(encodable)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Blog.SerializedObject.self)
                
                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.alias, encodable.alias)
                XCTAssertEqual(model.title, encodable.title)
                XCTAssertEqual(model.artworkUrl, encodable.artworkUrl)
                XCTAssertEqual(model.excerpt, encodable.excerpt)
                XCTAssertEqual(model.tags, encodable.tags)
                XCTAssertEqual(model.content, encodable.content)
                XCTAssertEqual(model.categories.count, encodable.categories.count)
                XCTAssertNotNil(model.createdAt)
                XCTAssertNotNil(model.updatedAt)
                if Self.meta.blog == nil {
                    Self.meta.blog = model
                }
            })
        )
        
        return model
    }
    
    @discardableResult
    func requestIndustry(_ data: Industry.SerializedObject? = nil) -> Industry.SerializedObject {
        guard data != nil || Self.meta.industry == nil else {
            return Self.meta.industry!
        }
        let expected = data ?? Industry.SerializedObject.generate()
        var model: Industry.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Industry.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Industry.SerializedObject.self)
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
    func requestJobExperience(_ data: Experience.SerializedObject? = nil) -> Experience.SerializedObject {
        
        guard data != nil || Self.meta.experience == nil else {
            return Self.meta.experience!
        }
        var expected = data ?? Experience.SerializedObject.generate()
        if data == nil {
            expected.industries = [requestIndustry()]
        }
        var model: Experience.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Experience.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Experience.SerializedObject.self)
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
    func requestEducation(_ data: Education.SerializedObject? = nil) -> Education.SerializedObject {
        guard data != nil || Self.meta.education == nil else {
            return Self.meta.education!
        }
        let expected = data ?? Education.SerializedObject.generate()
        var model: Education.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Education.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(Education.SerializedObject.self)
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
    func requestSocialNetworkingService(_ data: SocialNetworkingService.SerializedObject? = nil) -> SocialNetworkingService.SerializedObject {
        guard data != nil || Self.meta.socialNetworkingService == nil else {
            return Self.meta.socialNetworkingService!
        }
        let expected = data ?? SocialNetworkingService.SerializedObject.generate()
        var model: SocialNetworkingService.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, SocialNetworking.schema + "/services", headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(SocialNetworkingService.SerializedObject.self)
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
    func requestSocialNetworking(_ data: SocialNetworking.SerializedObject? = nil) -> SocialNetworking.SerializedObject {
        guard data != nil || Self.meta.socialNetworking == nil else {
            return Self.meta.socialNetworking!
        }
        var expected = data ?? SocialNetworking.SerializedObject.generate()
        if data == nil {
            expected.service = requestSocialNetworkingService()
        }
        
        var model: SocialNetworking.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, SocialNetworking.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                model = try $0.content.decode(SocialNetworking.SerializedObject.self)

                XCTAssertNotNil(model.id)
                XCTAssertNotNil(model.userId)
                XCTAssertEqual(model.url, expected.url)
                XCTAssertNotNil(model.service)
                XCTAssertEqual(model.service?.id, expected.service?.id)
                
                if Self.meta.socialNetworking == nil {
                    Self.meta.socialNetworking = model
                }
            })
        )
        return model

    }
    
    @discardableResult
    func requestProject(_ data: Project.SerializedObject? = nil) -> Project.SerializedObject {
        
        guard data != nil || Self.meta.project == nil else {
            return Self.meta.project!
        }
        let expected = data ?? Project.SerializedObject.generate()
        
        var model: Project.SerializedObject = .init()
        
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
    func requestSkill(_ data: Skill.SerializedObject? = nil) -> Skill.SerializedObject {
        guard data != nil || Self.meta.skill == nil else {
            return Self.meta.skill!
        }
        let expected = data ?? Skill.SerializedObject.generate()
        
        var model: Skill.SerializedObject = .init()
        
        XCTAssertNoThrow(
            try test(.POST, Skill.schema, headers: login().headers, beforeRequest: {
                try $0.content.encode(expected)
            }, afterResponse: {
                XCTAssertEqual($0.status, .ok)
                
                model = try $0.content.decode(Skill.SerializedObject.self)

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

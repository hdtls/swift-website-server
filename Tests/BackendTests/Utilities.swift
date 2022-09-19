import XCTVapor

@testable import Backend

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map({ _ in letters.randomElement()! }))
    }
}

extension User.Creation {
    static func generate() -> User.Creation {
        .init(
            firstName: .random(length: 6),
            lastName: .random(length: 7),
            username: .random(length: 8),
            password: .random(length: 9)
        )
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
        expected.name = .random(length: 5)
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
        expected.isOpenSource = false
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

func assertHTTPStatusEqualToUnauthorized(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .unauthorized)
}

func assertHTTPStatusEqualToOk(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .ok)
}

func assertHTTPStatusEqualToNotFound(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .notFound)
}

func assertHTTPStatusEqualToServerError(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .internalServerError)
}

func assertHTTPStatusEqualToBadRequest(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .badRequest)
}

func assertHTTPStatusEqualToUnprocessableEntity(_ response: XCTHTTPResponse) throws {
    XCTAssertEqual(response.status, .unprocessableEntity)
}

extension Application {

    struct LoggedInMsg {
        let registration: User.Creation
        let user: User.DTO
        let headers: HTTPHeaders
    }

    @discardableResult
    func registerUserWithLegacy(_ registration: User.Creation? = nil) -> User.DTO {
        let codable = registration ?? .generate()
        var user = User.DTO.init()
        XCTAssertNoThrow(
            try test(
                .POST,
                User.schema,
                beforeRequest: {
                    try $0.content.encode(codable)
                },
                afterResponse: {
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
                }
            )
        )

        return user
    }

    @discardableResult
    func login() -> LoggedInMsg {
        let registration = User.Creation.generate()
        let user = registerUserWithLegacy(registration)

        let credentials = "\(registration.username):\(registration.password)".data(using: .utf8)!
            .base64EncodedString()

        let headers = HTTPHeaders.init([("Authorization", "Basic \(credentials)")])

        var identityTokenString = ""

        XCTAssertNoThrow(
            try test(
                .POST,
                "authorize/basic",
                headers: headers,
                afterResponse: {
                    XCTAssertEqual($0.status, .ok)
                    identityTokenString = try $0.content.decode(AuthorizedMsg.self)
                        .identityTokenString
                }
            )
        )

        return .init(
            registration: registration,
            user: user,
            headers: .init([("Authorization", "Bearer " + identityTokenString)])
        )
    }

    func logout() throws {
        XCTAssertNoThrow(
            try test(
                .DELETE,
                "unauthorized",
                headers: login().headers,
                afterResponse: assertHTTPStatusEqualToOk
            )
        )
    }
}

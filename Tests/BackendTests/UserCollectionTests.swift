import XCTVapor

@testable import Backend

class UserCollectionTests: XCTestCase {

    private let uri = User.schema
    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        try app.setUp()
        try await app.autoMigrate()
    }

    override func tearDown() {
        XCTAssertNotNil(app)
        app.shutdown()
    }

    func testAuthorizeRequire() throws {
        XCTAssertNoThrow(
            try app.test(.PUT, uri + "/1", afterResponse: assertHTTPStatusEqualToUnauthorized)
        )
    }

    func testCreateUserWithInvalidPayload() throws {
        let json = [
            "firstName": "1",
            "lastName": "2",
            "password": "1234567",
            "username": "qwertyu",
        ]

        try app.test(
            .POST,
            uri,
            beforeRequest: {
                var payload = json
                payload["username"] = nil
                try $0.content.encode(payload)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .badRequest)
            }
        )
        .test(
            .POST,
            uri,
            beforeRequest: {
                var payload = json
                payload["firstName"] = nil
                try $0.content.encode(payload)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .badRequest)
                XCTAssertContains($0.body.string, "Value required for key 'firstName'")
            }
        )
        .test(
            .POST,
            uri,
            beforeRequest: {
                var payload = json
                payload["lastName"] = nil
                try $0.content.encode(payload)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .badRequest)
                XCTAssertContains($0.body.string, "Value required for key 'lastName'")
            }
        )
        .test(
            .POST,
            uri,
            beforeRequest: {
                var payload = json
                payload["password"] = nil
                try $0.content.encode(payload)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .badRequest)
            }
        )
    }

    func testCreateUserWithInvalidPassword() throws {
        try app.test(
            .POST,
            uri,
            beforeRequest: {
                var invalid = User.Creation.generate()

                invalid.password = "111"
                try $0.content.encode(invalid)
            },
            afterResponse: assertHTTPStatusEqualToBadRequest
        )
    }

    func testUniqueUsername() throws {
        let userCreation = User.Creation.generate()

        app.registerUserWithLegacy(userCreation)

        try app.test(
            .POST,
            uri,
            beforeRequest: {
                try $0.content.encode(userCreation)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .unprocessableEntity)
            }
        )
    }

    func testCreateUser() throws {
        app.registerUserWithLegacy(.generate())
    }

    func testQueryUserWithUserIDThatDoesNotExsit() throws {
        try app.test(.GET, uri + "/notfound", afterResponse: assertHTTPStatusEqualToNotFound)
            .test(.GET, uri + "/0", afterResponse: assertHTTPStatusEqualToNotFound)
    }

    func testQueryUserWithSpecifiedID() throws {
        let expected = app.registerUserWithLegacy()

        try app.test(
            .GET,
            uri + "/\(expected.username)",
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let model = try $0.content.decode(User.DTO.self)
                XCTAssertEqual(model, expected)
            }
        )
    }

    func testQueryUserWithUserIDAndQueryParameters() throws {
        let userCreation = app.login().user

        let query = "?emb=sns.edu.exp.skill.proj.blog"
        try app.test(
            .GET,
            uri + "/\(userCreation.username)\(query)",
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let user = try $0.content.decode(User.DTO.self)
                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, userCreation.username)
                XCTAssertEqual(user.firstName, userCreation.firstName)
                XCTAssertEqual(user.lastName, userCreation.lastName)
                XCTAssertNil(user.phone)
                XCTAssertNil(user.emailAddress)
                XCTAssertNil(user.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertGreaterThanOrEqual(user.social!.count, 0)
                XCTAssertGreaterThanOrEqual(user.projects!.count, 0)
                XCTAssertGreaterThanOrEqual(user.education!.count, 0)
                XCTAssertGreaterThanOrEqual(user.experiences!.count, 0)
                XCTAssertGreaterThanOrEqual(user.blog!.count, 0)
            }
        )
    }

    func testQueryWithUserIDAndQueryParametersAfterAddChildrens() throws {
        let msg = app.login()
        let userCreation = msg.user
        let headers = msg.headers

        var sns: SocialNetworkingService.DTO = .generate()
        var industry: Industry.DTO = .generate()

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                sns = try $0.content.decode(SocialNetworkingService.DTO.self)
            }
        )
        .test(
            .POST,
            SocialNetworking.schema,
            headers: headers,
            beforeRequest: {
                var payload = SocialNetworking.DTO.generate()
                payload.serviceId = sns.id
                try $0.content.encode(payload)
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                industry = try $0.content.decode(Industry.DTO.self)
            }
        )
        .test(
            .POST,
            Experience.schema,
            headers: headers,
            beforeRequest: {
                var payload = Experience.DTO.generate()
                payload.industries = [industry]
                try $0.content.encode(payload)
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Education.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Education.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Skill.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Skill.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Project.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Project.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(BlogCategory.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Blog.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Blog.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )

        let query = "?emb=sns.edu.exp.skill.proj.blog"

        try app.test(
            .GET,
            uri + "/\(userCreation.username)\(query)",
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                let user = try $0.content.decode(User.DTO.self)
                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, userCreation.username)
                XCTAssertEqual(user.firstName, userCreation.firstName)
                XCTAssertEqual(user.lastName, userCreation.lastName)
                XCTAssertNil(user.phone)
                XCTAssertNil(user.emailAddress)
                XCTAssertNil(user.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertGreaterThanOrEqual(user.social!.count, 1)
                XCTAssertGreaterThanOrEqual(user.projects!.count, 1)
                XCTAssertGreaterThanOrEqual(user.education!.count, 1)
                XCTAssertGreaterThanOrEqual(user.experiences!.count, 1)
                XCTAssertGreaterThanOrEqual(user.blog!.count, 1)
                XCTAssertNotNil(user.skill)
            }
        )
    }

    func testQueryAllUsers() throws {
        try app.test(
            .GET,
            uri,
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                XCTAssertNoThrow(try $0.content.decode([User.DTO].self))
            }
        )
    }

    func testQueryAllWithQueryParametersAfterAddChildrens() throws {
        let msg = app.login()
        let userCreation = msg.user
        let headers = msg.headers

        var sns: SocialNetworkingService.DTO = .generate()
        var industry: Industry.DTO = .generate()

        try app.test(
            .POST,
            SocialNetworking.schema + "/services",
            beforeRequest: {
                try $0.content.encode(SocialNetworkingService.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                sns = try $0.content.decode(SocialNetworkingService.DTO.self)
            }
        )
        .test(
            .POST,
            SocialNetworking.schema,
            headers: headers,
            beforeRequest: {
                var payload = SocialNetworking.DTO.generate()
                payload.serviceId = sns.id
                try $0.content.encode(payload)
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Industry.schema,
            beforeRequest: {
                try $0.content.encode(Industry.DTO.generate())
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                industry = try $0.content.decode(Industry.DTO.self)
            }
        )
        .test(
            .POST,
            Experience.schema,
            headers: headers,
            beforeRequest: {
                var payload = Experience.DTO.generate()
                payload.industries = [industry]
                try $0.content.encode(payload)
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Education.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Education.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Skill.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Skill.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Project.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Project.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            BlogCategory.schema,
            beforeRequest: {
                try $0.content.encode(BlogCategory.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )
        .test(
            .POST,
            Blog.schema,
            headers: headers,
            beforeRequest: {
                try $0.content.encode(Blog.DTO.generate())
            },
            afterResponse: assertHTTPStatusEqualToOk
        )

        let query = "?emb=sns.edu.exp.skill.proj.blog"

        try app.test(
            .GET,
            uri + query,
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let users = try $0.content.decode([User.DTO].self)
                XCTAssertNotNil(users.first)

                let user = users.filter({
                    $0.username == userCreation.username
                }).first!

                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, userCreation.username)
                XCTAssertEqual(user.firstName, userCreation.firstName)
                XCTAssertEqual(user.lastName, userCreation.lastName)
                XCTAssertNil(user.phone)
                XCTAssertNil(user.emailAddress)
                XCTAssertNil(user.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertGreaterThanOrEqual(user.social!.count, 1)
                XCTAssertGreaterThanOrEqual(user.education!.count, 1)
                XCTAssertGreaterThanOrEqual(user.experiences!.count, 1)
                XCTAssertGreaterThanOrEqual(user.projects!.count, 1)
                XCTAssertGreaterThanOrEqual(user.blog!.count, 1)
                XCTAssertNotNil(user.skill)
            }
        )
    }

    func testUpdateUser() throws {
        let msg = app.login()
        var userCreation = msg.user
        userCreation.firstName = .random(length: 7)
        userCreation.lastName = .random(length: 8)
        userCreation.phone = .random(length: 11)
        userCreation.emailAddress = .random(length: 10)
        userCreation.aboutMe = .random(length: 32)

        try app.test(
            .PUT,
            uri + "/\(userCreation.username)",
            headers: msg.headers,
            beforeRequest: {

                try $0.content.encode(userCreation)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let user = try $0.content.decode(User.DTO.self)
                XCTAssertNotNil(user.id)
                XCTAssertEqual(user.username, userCreation.username)
                XCTAssertEqual(user.firstName, userCreation.firstName)
                XCTAssertEqual(user.lastName, userCreation.lastName)
                XCTAssertEqual(user.phone, userCreation.phone)
                XCTAssertEqual(user.emailAddress, userCreation.emailAddress)
                XCTAssertEqual(user.aboutMe, userCreation.aboutMe)
                XCTAssertNil(user.location)
                XCTAssertNil(user.social)
                XCTAssertNil(user.education)
                XCTAssertNil(user.experiences)
            }
        )
    }

    func testQueryBlogThatAssociatedWithSpecialUser() throws {
        let msg = app.login()
        var expected = Blog.DTO.generate()

        try app.test(
            .POST,
            Blog.schema,
            headers: msg.headers,
            beforeRequest: {
                try $0.content.encode(expected)
            },
            afterResponse: {
                XCTAssertEqual($0.status, .ok)
                expected = try $0.content.decode(Blog.DTO.self)
            }
        )
        .test(
            .GET,
            uri + "/\(msg.user.username)" + "/blog",
            afterResponse: {
                XCTAssertEqual($0.status, .ok)

                let models = try $0.content.decode([Blog.DTO].self)
                expected.content = nil
                XCTAssertTrue(models.contains(expected))
            }
        )
    }
}

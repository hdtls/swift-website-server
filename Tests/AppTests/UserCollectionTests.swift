import XCTVapor
@testable import App

class UserCollectionTests: XCTestCase {
    
    let path = User.schema
    var app: Application!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = .init(.testing)
        try bootstrap(app)
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreateWithInvalidPayload() throws {
        let json = [
            "firstName" : "1",
            "lastName" : "2",
            "password" : "1234567",
            "username" : "qwertyu"
        ]

        try app.test(.POST, path, beforeRequest: {
            var payload = json
            payload["username"] = nil
            try $0.content.encode(payload)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
        })
        .test(.POST, path, beforeRequest: {
            var payload = json
            payload["firstName"] = nil
            try $0.content.encode(payload)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value required for key 'firstName'")
        })
        .test(.POST, path, beforeRequest: {
            var payload = json
            payload["lastName"] = nil
            try $0.content.encode(payload)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
            XCTAssertContains($0.body.string, "Value required for key 'lastName'")
        })
        .test(.POST, path, beforeRequest: {
            var payload = json
            payload["password"] = nil
            try $0.content.encode(payload)
        }, afterResponse: {
            XCTAssertEqual($0.status, .badRequest)
//            XCTAssertContains($0.body.string, "Value required for key 'password'")
        })
    }
    
    func testCreateWithInvalidPassword() throws {
        try app.test(.POST, path, beforeRequest: {
            var invalid = User.Creation.generate()

            invalid.password = "111"
            try $0.content.encode(invalid)
        }, afterResponse: assertHttpBadRequest)
    }
    
    func testCreateWithConflictUsername() throws {
        let userCreation = User.Creation.generate()
        
        app.registerUserWithLegacy(userCreation)
        
        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(userCreation)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
        })
    }
    
    func testCreate() throws {
        app.registerUserWithLegacy(.generate())
    }
    
    func testQueryWithUserIDThatDoesNotExsit() throws {
        try app.test(.GET, path + "/notfound", afterResponse: assertHttpNotFound)
            .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithUserID() throws {
        var user = app.registerUserWithLegacy()
        
        try app.test(.GET, path + "/\(user.username)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, user.username)
            XCTAssertEqual(user.firstName, user.firstName)
            XCTAssertEqual(user.lastName, user.lastName)
            XCTAssertNil(user.phone)
            XCTAssertNil(user.emailAddress)
            XCTAssertNil(user.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.social)
            XCTAssertNil(user.education)
            XCTAssertNil(user.experiences)
        })
    }
    
    func testQueryWithUserIDAndQueryParameters() throws {
        let userCreation = app.login().user
        
        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true&incl_blog=true"
        try app.test(.GET, path + "/\(userCreation.username)\(query)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let user = try $0.content.decode(User.Coding.self)
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
        })
    }

    func testQueryWithUserIDAndQueryParametersAfterAddChildrens() throws {
        let userCreation = app.login().user
        
        app.requestSocialNetworking()
        app.requestJobExperience()
        app.requestEducation()
        app.requestProject()
        app.requestSkill()
        app.requestBlog()

        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true&incl_blog=true"
        try app.test(.GET, path + "/\(userCreation.username)\(query)", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            let user = try $0.content.decode(User.Coding.self)
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
        })
    }

    func testQueryAll() throws {
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
        })
    }
    
    func testQueryAllWithQueryParametersAfterAddChildrens() throws {
        let userCreation = app.login().user
        app.requestSocialNetworking()
        app.requestJobExperience()
        app.requestEducation()
        app.requestProject()
        app.requestSkill()
        app.requestBlog()
        
        let query = "?incl_sns=true&incl_edu_exp=true&incl_wrk_exp=true&incl_skill=true&incl_projs=true&incl_blog=true"
        try app.test(.GET, path + query, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let users = try $0.content.decode([User.Coding].self)
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
        })
    }
    
    func testUpdate() throws {
        var userCreation = app.login().user
        userCreation.firstName = .random(length: 7)
        userCreation.lastName = .random(length: 8)
        userCreation.phone = .random(length: 11)
        userCreation.emailAddress = .random(length: 10)
        userCreation.aboutMe = .random(length: 32)
        
        try app.test(.PUT, path + "/\(userCreation.username)", headers: app.login().headers, beforeRequest: {
            
            try $0.content.encode(userCreation)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let user = try $0.content.decode(User.Coding.self)
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
        })
    }

    func testQueryBlogThatAssociatedWithSpecialUser() throws {
        let blog = app.requestBlog(.generate())

        try app.test(.GET, path + "/\(app.login().user.username)" + "/blog", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let serializedBlog = try $0.content.decode([Blog.DTO].self).filter({ $0.id == blog.id }).first

            XCTAssertNotNil(serializedBlog)
            XCTAssertEqual(serializedBlog?.id, blog.id)
            XCTAssertEqual(serializedBlog?.alias, blog.alias)
            XCTAssertEqual(serializedBlog?.title, blog.title)
            XCTAssertEqual(serializedBlog?.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(serializedBlog?.excerpt, blog.excerpt)
            XCTAssertEqual(serializedBlog?.tags, blog.tags)
            XCTAssertEqual(serializedBlog?.userId, blog.userId)
        })
    }
}

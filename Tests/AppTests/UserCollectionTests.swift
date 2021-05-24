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
            var invalid = User.Creation.init(firstName: "J", lastName: "K", username: "test", password: "111111")

            invalid.password = "111"
            try $0.content.encode(invalid)
        }, afterResponse: assertHttpBadRequest)
    }
    
    func testCreateWithConflictUsername() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )

        try registUserAndLoggedIn(app, userCreation, headers: nil)
        
        try app.test(.POST, path, beforeRequest: {
            try $0.content.encode(userCreation)
        }, afterResponse: {
            XCTAssertEqual($0.status, .unprocessableEntity)
        })
    }
    
    func testCreate() throws {
        try registUserAndLoggedIn(app)
    }
    
    func testQueryWithUserIDThatDoesNotExsit() throws {
        try app.test(.GET, path + "/notfound", afterResponse: assertHttpNotFound)
            .test(.GET, path + "/" + UUID().uuidString, afterResponse: assertHttpNotFound)
    }
    
    func testQueryWithUserID() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )
        
        try registUserAndLoggedIn(app, userCreation, headers: nil)
        
        var user: User.SerializedObject!
        
        try app.test(.GET, path + "/\(userCreation.username)", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            user = try! $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, userCreation.username)
            XCTAssertEqual(user.firstName, userCreation.firstName)
            XCTAssertEqual(user.lastName, userCreation.lastName)
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
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )
        
        try registUserAndLoggedIn(app, userCreation, headers: nil)

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
            XCTAssertEqual(user.social, [])
            XCTAssertEqual(user.projects, [])
            XCTAssertEqual(user.education, [])
            XCTAssertEqual(user.experiences, [])
            XCTAssertEqual(user.blog, [])
            XCTAssertNil(user.skill)
        })
    }

    func testQueryWithUserIDAndQueryParametersAfterAddChildrens() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )

        let headers = try registUserAndLoggedIn(app, userCreation, headers: nil)

        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)
        let workExp = try assertCreateWorkExperiance(app, headers: headers)
        let eduExp = try assertCreateEduExperiance(app, headers: headers)
        let proj = try assertCreateProj(app, headers: headers)
        let skill = try assertCreateSkill(app, headers: headers)
        var blog = try assertCreateBlog(app, headers: headers)
        blog.content = nil

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
            XCTAssertEqual(user.social?.count, 1)
            XCTAssertEqual(user.social?.first, socialNetworking)
            XCTAssertEqual(user.projects?.count, 1)
            XCTAssertEqual(user.projects?.first, proj)
            XCTAssertEqual(user.education?.count, 1)
            XCTAssertEqual(user.education?.first, eduExp)
            XCTAssertEqual(user.experiences?.count, 1)
            XCTAssertEqual(user.experiences?.first, workExp)
            XCTAssertEqual(user.blog?.count, 1)
            XCTAssertEqual(user.blog?.first, blog)
            XCTAssertEqual(user.skill, skill)
        })
        .test(.DELETE, Blog.schema + "/\(blog.id!.uuidString)", headers: headers)
    }

    func testQueryAll() throws {
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
        })
        
        try registUserAndLoggedIn(app)
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
        })
    }
    
    func testQueryAllWithQueryParametersAfterAddChildrens() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )

        let headers = try registUserAndLoggedIn(app, userCreation, headers: nil)

        let socialNetworking = try assertCreateSocialNetworking(app, headers: headers)
        let workExpCoding = try assertCreateWorkExperiance(app, headers: headers)
        let eduExpCoding = try assertCreateEduExperiance(app, headers: headers)
        let projCoding = try assertCreateProj(app, headers: headers)
        let skillCoding = try assertCreateSkill(app, headers: headers)
        var blog = try assertCreateBlog(app, headers: headers)
        blog.content = nil
        
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
            XCTAssertEqual(user.social!.count, 1)
            XCTAssertEqual(user.social!.first, socialNetworking)
            XCTAssertEqual(user.education!.count, 1)
            XCTAssertEqual(user.education!.first, eduExpCoding)
            XCTAssertEqual(user.experiences!.count, 1)
            XCTAssertEqual(user.experiences!.first, workExpCoding)
            XCTAssertEqual(user.projects!.count, 1)
            XCTAssertEqual(user.projects!.first, projCoding)
            XCTAssertEqual(user.blog!.count, 1)
            XCTAssertEqual(user.blog!.first, blog)
            XCTAssertNotNil(user.skill)
            XCTAssertEqual(user.skill, skillCoding)
        })
        .test(.DELETE, Blog.schema + "/\(blog.id!.uuidString)", headers: headers)
    }
    
    func testUpdate() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )

        let headers = try registUserAndLoggedIn(app, userCreation, headers: nil)
        
        let upgrade = User.Coding.init(
            username: userCreation.username,
            firstName: "R",
            lastName: "J",
            phone: "+1 888888888",
            emailAddress: "test@test.com",
            aboutMe: "HELLO WORLD !!!"
        )
        
        try app.test(.PUT, path + "/\(userCreation.username)", headers: headers, beforeRequest: {
            
            try $0.content.encode(upgrade)
        }, afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let user = try $0.content.decode(User.Coding.self)
            XCTAssertNotNil(user.id)
            XCTAssertEqual(user.username, upgrade.username)
            XCTAssertEqual(user.firstName, upgrade.firstName)
            XCTAssertEqual(user.lastName, upgrade.lastName)
            XCTAssertEqual(user.phone, upgrade.phone)
            XCTAssertEqual(user.emailAddress, upgrade.emailAddress)
            XCTAssertEqual(user.aboutMe, upgrade.aboutMe)
            XCTAssertNil(user.location)
            XCTAssertNil(user.social)
            XCTAssertNil(user.education)
            XCTAssertNil(user.experiences)
        })
    }

    func testQueryBlogThatAssociatedWithSpecialUser() throws {
        let userCreation = User.Creation.init(
            firstName: "J",
            lastName: "K",
            username: String(UUID().uuidString.prefix(8)),
            password: "111111"
        )

        let headers = try registUserAndLoggedIn(app, userCreation, headers: nil)
        let blog = try assertCreateBlog(app, headers: headers)

        try app.test(.GET, path + "/\(userCreation.username)" + "/blog", afterResponse: {
            XCTAssertEqual($0.status, .ok)

            let serializedBlog = try $0.content.decode([Blog.SerializedObject].self).first

            XCTAssertNotNil(serializedBlog)
            XCTAssertEqual(serializedBlog?.id, blog.id)
            XCTAssertEqual(serializedBlog?.alias, blog.alias)
            XCTAssertEqual(serializedBlog?.title, blog.title)
            XCTAssertEqual(serializedBlog?.artworkUrl, blog.artworkUrl)
            XCTAssertEqual(serializedBlog?.excerpt, blog.excerpt)
            XCTAssertEqual(serializedBlog?.tags, blog.tags)
            XCTAssertEqual(serializedBlog?.createdAt, blog.createdAt)
            XCTAssertEqual(serializedBlog?.updatedAt, blog.updatedAt)
            XCTAssertEqual(serializedBlog?.userId, blog.userId)
        })
        .test(.DELETE, Blog.schema + "/\(blog.id!.uuidString)", headers: headers)
    }
}

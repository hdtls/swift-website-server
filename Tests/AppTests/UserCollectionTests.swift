import XCTVapor
@testable import App

class UserCollectionTests: XCAppCase {
    
    let path = User.schema

    func testAuthorizeRequire() {
        XCTAssertNoThrow(
            try app.test(.PUT, path + "/1", afterResponse: assertHttpUnauthorized)
        )
    }

    func testCreateWithInvalidPayload() throws {
        let json = [
            "firstName" : userCreation.firstName,
            "lastName" : userCreation.lastName,
            "password" : userCreation.password,
            "username" : userCreation.username
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
            var invalid = userCreation
            invalid.password = "111"
            try $0.content.encode(invalid)
        }, afterResponse: assertHttpBadRequest)
    }
    
    func testCreateWithConflictUsername() throws {
        try registUserAndLoggedIn(app)
        
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
        try registUserAndLoggedIn(app, userCreation)
        
        try app.test(.GET, path + "/\(userCreation.username)", afterResponse: {
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
            XCTAssertNil(user.social)
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.workExps)
        })
    }
    
    func testQueryWithUserIDAndQueryParameters() throws {
        try registUserAndLoggedIn(app, userCreation)

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
            XCTAssertEqual(user.eduExps, [])
            XCTAssertEqual(user.workExps, [])
            XCTAssertEqual(user.blog, [])
            XCTAssertNil(user.skill)
        })
    }

    func testQueryWithUserIDAndQueryParametersAfterAddChildrens() throws {
        let headers = try registUserAndLoggedIn(app, userCreation)

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
            XCTAssertEqual(user.eduExps?.count, 1)
            XCTAssertEqual(user.eduExps?.first, eduExp)
            XCTAssertEqual(user.workExps?.count, 1)
            XCTAssertEqual(user.workExps?.first, workExp)
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
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 0)
        })
        
        try registUserAndLoggedIn(app)
        
        try app.test(.GET, path, afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertNoThrow(try $0.content.decode([User.Coding].self))
            XCTAssertEqual(try! $0.content.decode([User.Coding].self).count, 1)
        })
    }
    
    func testQueryAllWithQueryParametersAfterAddChildrens() throws {
        let headers = try registUserAndLoggedIn(app, userCreation)

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
            XCTAssertEqual(users.count, 1)
            XCTAssertNotNil(users.first)
            
            let user = users.first!
            
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
            XCTAssertEqual(user.eduExps!.count, 1)
            XCTAssertEqual(user.eduExps!.first, eduExpCoding)
            XCTAssertEqual(user.workExps!.count, 1)
            XCTAssertEqual(user.workExps!.first, workExpCoding)
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
        let headers = try registUserAndLoggedIn(app)
        let upgrade = User.Coding.init(
            username: "test",
            firstName: "R",
            lastName: "J",
            phone: "+1 888888888",
            emailAddress: "test@test.com",
            aboutMe: "HELLO WORLD !!!"
        )
        try app.test(.PUT, path + "/test", headers: headers, beforeRequest: {
            
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
            XCTAssertNil(user.eduExps)
            XCTAssertNil(user.workExps)
        })
    }

    func testQueryBlogThatAssociatedWithSpecialUser() throws {
        let headers = try registUserAndLoggedIn(app)
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

import XCTVapor
@testable import App

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

let userCreation = User.Creation.init(firstName: "J", lastName: "K", username: "test", password: "111111")
@discardableResult
func registUserAndLoggedIn(
    _ app: Application,
    _ userCreation: User.Creation = userCreation,
    headers: HTTPHeaders? = nil
) throws -> HTTPHeaders {

    var httpHeaders = headers
    guard httpHeaders == nil else {
        return httpHeaders!
    }

    try app.test(.POST, "users", beforeRequest: {
        try $0.content.encode(userCreation)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let authorizeMsg = try $0.content.decode(AuthorizeMsg.self)

        XCTAssertNotNil(authorizeMsg.accessToken)
        XCTAssertNotNil(authorizeMsg.user)
        XCTAssertNotNil(authorizeMsg.user.id)
        XCTAssertEqual(authorizeMsg.user.username, userCreation.username)
        XCTAssertEqual(authorizeMsg.user.firstName, userCreation.firstName)
        XCTAssertEqual(authorizeMsg.user.lastName, userCreation.lastName)
        XCTAssertNil(authorizeMsg.user.screenName)
        XCTAssertNil(authorizeMsg.user.phone)
        XCTAssertNil(authorizeMsg.user.emailAddress)
        XCTAssertNil(authorizeMsg.user.aboutMe)
        XCTAssertNil(authorizeMsg.user.location)
        XCTAssertNil(authorizeMsg.user.eduExps)
        XCTAssertNil(authorizeMsg.user.workExps)
        XCTAssertNil(authorizeMsg.user.hobbies)

        httpHeaders = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Bearer " + authorizeMsg.accessToken))
    })

    return httpHeaders!
}

@discardableResult
func assertCreateSocialNetworkingService(
    _ app: Application
) throws -> SocialNetworkingService.Coding {

    let socialNetworkingService = SocialNetworkingService.Coding.init(type: .twitter)

    var service: SocialNetworkingService.Coding!

    try app.test(.POST, "social/services", beforeRequest: {
        try $0.content.encode(socialNetworkingService)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let coding = try $0.content.decode(SocialNetworkingService.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.type)

        service = coding
    })

    return service
}

@discardableResult
func assertCreateSocialNetworking(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> SocialNetworking.Coding {

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: SocialNetworking.Coding!

    let service = try assertCreateSocialNetworkingService(app)

    try app.test(.POST, "social", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(
            SocialNetworking.Coding.init(url: "https://twitter.com/uid", service: service)
        )
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)
        coding = try $0.content.decode(SocialNetworking.Coding.self)

        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.url, "https://twitter.com/uid")
        XCTAssertNotNil(coding.service)
        XCTAssertEqual(coding.service?.id, service.id)
    })

    return coding
}

@discardableResult
func assertCreateIndustry(
    _ app: Application,
    industry: Industry.Coding? = nil
) throws -> Industry.Coding {

    var coding: Industry.Coding!

    try app.test(.POST, Industry.schema, beforeRequest: {
        try $0.content.encode(industry ?? Industry.Coding.init(title: "International Trade & Development"))
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Industry.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.title, industry?.title ?? "International Trade & Development")

    })

    return coding
}

@discardableResult
func assertCreateWorkExperiance(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> WorkExp.Coding {
    let exp = WorkExp.Coding.init(
        title: "iOS Developer",
        companyName: "XXX",
        location: "XXX",
        startDate: "2020-02-20",
        endDate: "-",
        industry: [
            Industry.Coding.init(title: "International Trade & Development")
        ]
    )
    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)
    let industry = try assertCreateIndustry(app, industry: exp.industry.first)

    var coding: WorkExp.Coding!

    try app.test(.POST, "exp/works", headers: httpHeaders, beforeRequest: {
        var workExpCoding = exp
        workExpCoding.industry = [industry]
        try $0.content.encode(workExpCoding)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(WorkExp.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.title, exp.title)
        XCTAssertEqual(coding.companyName, exp.companyName)
        XCTAssertEqual(coding.location, exp.location)
        XCTAssertEqual(coding.startDate, exp.startDate)
        XCTAssertEqual(coding.endDate, exp.endDate)
        XCTAssertEqual(coding.industry.count, 1)
        XCTAssertEqual(coding.industry.first!.id, industry.id)
        XCTAssertEqual(coding.industry.first!.title, industry.title)
        XCTAssertNil(coding.headline)
        XCTAssertNil(coding.responsibilities)
    })

    return coding
}

@discardableResult
func assertCreateEduExperiance(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> EducationalExp.Coding {

    let edu = EducationalExp.Coding.init(
        school: "BALABALA",
        degree: "PhD",
        field: "xxx",
        startYear: "2010",
        activities: ["xxxxx"]
    )

    let headers = try registUserAndLoggedIn(app, headers: headers)
    var coding: EducationalExp.Coding!

    try app.test(.POST, "exp/edu", headers: headers, beforeRequest: {
        try $0.content.encode(edu)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(EducationalExp.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.school, edu.school)
        XCTAssertEqual(coding.degree, edu.degree)
        XCTAssertEqual(coding.field, edu.field)
        XCTAssertEqual(coding.startYear, edu.startYear)
        XCTAssertNil(coding.endYear)
        XCTAssertEqual(coding.activities, edu.activities)
        XCTAssertNil(coding.accomplishments)
    })

    return coding
}

@discardableResult
func assertCreateSkill(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> Skill.Coding {
    let skill = Skill.Coding.init(profesional: ["xxx"], workflow: ["xxx"])

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Skill.Coding!

    try app.test(.POST, "skills", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(skill)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Skill.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.profesional, skill.profesional)
        XCTAssertEqual(coding.workflow, skill.workflow)
    })

    return coding
}

@discardableResult
func assertCreateProj(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> Project.Coding {

    let proj = Project.Coding.init(name: "proj", summary: "proj_summary", startDate: "start_date", endDate: "end_date")

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Project.Coding!

    try app.test(.POST, "projects", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(proj)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Project.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.name, proj.name)
        XCTAssertEqual(coding.categories, proj.categories)
        XCTAssertEqual(coding.summary, proj.summary)
        XCTAssertEqual(coding.startDate, proj.startDate)
        XCTAssertEqual(coding.endDate, proj.endDate)
        XCTAssertNotNil(coding.userId)
    })

    return coding
}

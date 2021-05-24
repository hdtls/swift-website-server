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

var authorized: HTTPHeaders?

@discardableResult
func registUserAndLoggedIn(
    _ app: Application,
    _ userCreation: User.Creation = .init(firstName: "z", lastName: "f", username: String(UUID().uuidString.prefix(8)), password: "uuidString"),
    headers: HTTPHeaders? = authorized
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
        XCTAssertNil(authorizeMsg.user.phone)
        XCTAssertNil(authorizeMsg.user.emailAddress)
        XCTAssertNil(authorizeMsg.user.aboutMe)
        XCTAssertNil(authorizeMsg.user.location)
        XCTAssertNil(authorizeMsg.user.education)
        XCTAssertNil(authorizeMsg.user.experiences)
        XCTAssertNil(authorizeMsg.user.interests)

        httpHeaders = HTTPHeaders.init(dictionaryLiteral: ("Authorization", "Bearer " + authorizeMsg.accessToken))
        authorized = httpHeaders
    })

    return httpHeaders!
}

@discardableResult
func assertCreateSocialNetworkingService(
    _ app: Application
) throws -> SocialNetworkingService.Coding {

    let socialNetworkingService = SocialNetworkingService.Coding.init(type: .twitter)

    var service: SocialNetworkingService.Coding!

    try app.test(.POST, "\(SocialNetworking.schema)/services", beforeRequest: {
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
    headers: HTTPHeaders? = authorized
) throws -> SocialNetworking.Coding {

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: SocialNetworking.Coding!

    let service = try assertCreateSocialNetworkingService(app)

    try app.test(.POST, SocialNetworking.schema, headers: httpHeaders, beforeRequest: {
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

    var expect = industry
    
    if expect == nil {
        expect = Industry.Coding.init(title: String(UUID().uuidString.prefix(6)))
    }

    try app.test(.POST, Industry.schema, beforeRequest: {
        try $0.content.encode(expect!)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        let coding = try $0.content.decode(Industry.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.title, expect?.title)
        
        expect = coding
    })

    return expect!
}

@discardableResult
func assertCreateWorkExperiance(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> Experience.SerializedObject {
    let exp = Experience.SerializedObject.init(
        title: "iOS Developer",
        companyName: "XXX",
        location: "XXX",
        startDate: "2020-02-20",
        endDate: "-",
        industries: [
            Industry.SerializedObject.init(title: String(UUID().uuidString.prefix(6)))
        ]
    )
    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)
    let industry = try assertCreateIndustry(app, industry: exp.industries.first)

    var coding: Experience.SerializedObject!

    try app.test(.POST, Experience.schema, headers: httpHeaders, beforeRequest: {
        var workExpCoding = exp
        workExpCoding.industries = [industry]
        try $0.content.encode(workExpCoding)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Experience.SerializedObject.self)
        XCTAssertNotNil(coding.id)
        XCTAssertNotNil(coding.userId)
        XCTAssertEqual(coding.title, exp.title)
        XCTAssertEqual(coding.companyName, exp.companyName)
        XCTAssertEqual(coding.location, exp.location)
        XCTAssertEqual(coding.startDate, exp.startDate)
        XCTAssertEqual(coding.endDate, exp.endDate)
        XCTAssertEqual(coding.industries.count, 1)
        XCTAssertEqual(coding.industries.first!.id, industry.id)
        XCTAssertEqual(coding.industries.first!.title, industry.title)
        XCTAssertNil(coding.headline)
        XCTAssertNil(coding.responsibilities)
    })

    return coding
}

@discardableResult
func assertCreateEduExperiance(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> Education.Coding {

    let edu = Education.Coding.init(
        school: "BALABALA",
        degree: "PhD",
        field: "xxx",
        startYear: "2010",
        activities: ["xxxxx"]
    )

    let headers = try registUserAndLoggedIn(app, headers: headers)
    var coding: Education.Coding!

    try app.test(.POST, Education.schema, headers: headers, beforeRequest: {
        try $0.content.encode(edu)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Education.Coding.self)
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
func assertCreateProj(
    _ app: Application,
    headers: HTTPHeaders? = nil
) throws -> Project.Coding {

    let proj = Project.Coding.init(name: "proj", summary: "proj_summary", kind: .app, visibility: .public, startDate: "start_date", endDate: "end_date")

    let httpHeaders = try registUserAndLoggedIn(app, headers: headers)

    var coding: Project.Coding!

    try app.test(.POST, "projects", headers: httpHeaders, beforeRequest: {
        try $0.content.encode(proj)
    }, afterResponse: {
        XCTAssertEqual($0.status, .ok)

        coding = try $0.content.decode(Project.Coding.self)
        XCTAssertNotNil(coding.id)
        XCTAssertEqual(coding.name, proj.name)
        XCTAssertEqual(coding.note, proj.note)
        XCTAssertEqual(coding.genres, proj.genres)
        XCTAssertEqual(coding.summary, proj.summary)
        XCTAssertEqual(coding.artworkUrl, proj.artworkUrl)
        XCTAssertEqual(coding.backgroundImageUrl, proj.backgroundImageUrl)
        XCTAssertEqual(coding.promoImageUrl, proj.promoImageUrl)
        XCTAssertEqual(coding.screenshotUrls, proj.screenshotUrls)
        XCTAssertEqual(coding.padScreenshotUrls, proj.padScreenshotUrls)
        XCTAssertEqual(coding.kind, proj.kind)
        XCTAssertEqual(coding.visibility, proj.visibility)
        XCTAssertEqual(coding.trackViewUrl, proj.trackViewUrl)
        XCTAssertEqual(coding.trackId, proj.trackId)
        XCTAssertEqual(coding.startDate, proj.startDate)
        XCTAssertEqual(coding.endDate, proj.endDate)
        XCTAssertNotNil(coding.userId)
    })

    return coding
}

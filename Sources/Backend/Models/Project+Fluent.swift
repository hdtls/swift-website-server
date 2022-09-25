import Fluent
import Vapor

enum ProjKind: String, CaseIterable, Codable {
    static let schema: String = "project_kinds"

    case app
    case website
    case library
}

enum ProjVisibility: String, CaseIterable, Codable {
    static let schema: String = "project_visibility"

    case `private`
    case `public`
}

extension Project.DTO {

    mutating func beforeEncode() throws {
        artworkUrl = artworkUrl?.bucketURLString()
        backgroundImageUrl = backgroundImageUrl?.bucketURLString()
        padScreenshotUrls = padScreenshotUrls?.map { $0.bucketURLString() }
        screenshotUrls = screenshotUrls?.map { $0.bucketURLString() }
        promoImageUrl = promoImageUrl?.bucketURLString()
    }
}

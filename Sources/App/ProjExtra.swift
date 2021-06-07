import Vapor
import Fluent

enum ProjKind: String, CaseIterable, Codable {
    static let schema: String = "project_kinds"
    
    case app
    case website
    case repositry
}

enum ProjVisibility: String, CaseIterable, Codable {
    static let schema: String = "project_visibility"
    
    case `private`
    case `public`
}

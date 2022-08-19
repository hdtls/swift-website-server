import Vapor
import Fluent

protocol Repository {
        
    var req: Request { get }

    init(req: Request)
}

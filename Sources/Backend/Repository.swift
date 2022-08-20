import Vapor

protocol Repository {

    var req: Request { get }

    init(req: Request)
}

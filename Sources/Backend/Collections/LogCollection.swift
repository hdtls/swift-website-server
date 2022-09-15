import Vapor

class LogCollection: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped([
            User.authenticator()
        ])
        
        let authorize = routes.grouped("authorize")
        authorize.on(.POST, "basic", use: authWithBasic)
        
        let trusted = routes.grouped([
            Token.authenticator(),
            Token.guardMiddleware(),
            User.guardMiddleware(),
        ])
        trusted.on(.DELETE, "unauthorized", use: unauthorized)
    }
    
    func authWithBasic(_ req: Request) async throws -> AuthorizedMsg {
        if req.auth.has(User.self) && req.auth.has(Token.self) {
            // If user already logged in, just return authorized msg.
            let user = try req.auth.require(User.self)
            let token = try req.auth.require(Token.self)
            return try AuthorizedMsg(user: user, token: token)
        } else {
            let user = try req.auth.require(User.self)
            let token = try Token.init(user)
            try await token.save(on: req.db)
            req.auth.login(user)
            req.auth.login(token)
            return try AuthorizedMsg(user: user, token: token)
        }
    }
    
    func unauthorized(_ req: Request) async throws -> HTTPResponseStatus {
        let token = try req.auth.require(Token.self)
        try await token.delete(on: req.db)
        req.auth.logout(User.self)
        req.auth.logout(Token.self)
        return .ok
    }
}

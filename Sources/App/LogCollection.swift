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
            User.guardMiddleware()
        ])
        trusted.on(.DELETE, "unauthorized", use: unauthorized)
    }
    
    func authWithBasic(_ request: Request) throws -> EventLoopFuture<AuthorizedMsg> {
        if request.auth.has(User.self) && request.auth.has(Token.self) {
                // If user already logged in, just return authorized msg.
            let user = try request.auth.require(User.self)
            let token = try request.auth.require(Token.self)
            return try request.eventLoop.makeSucceededFuture(AuthorizedMsg(user: user, token: token))
        } else {
            let user = try request.auth.require(User.self)
            let token = try Token.init(user)
            return token.save(on: request.db)
                .flatMapThrowing({
                    request.auth.login(user)
                    request.auth.login(token)
                    return try AuthorizedMsg(user: user, token: token)
                })
        }
    }
    
    func unauthorized(_ request: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        try request.auth.require(Token.self)
            .delete(on: request.db)
            .map({
                request.auth.logout(User.self)
                request.auth.logout(Token.self)
                return .ok
            })
    }
    
}

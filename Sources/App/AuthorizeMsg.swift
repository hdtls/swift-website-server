import Vapor

struct AuthorizeMsg: Content {
    let user: User.Coding
    let accessToken: String

    init(user: User.Coding, token: Token) {
        self.user = user
        self.accessToken = token.token
    }
}

import Vapor

extension Request {
    var user: User {
        get throws {
            try auth.require()
        }
    }

    var uid: User.IDValue {
        get throws {
            try user.requireID()
        }
    }
}

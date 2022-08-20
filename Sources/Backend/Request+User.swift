import Vapor

extension Request {

    var owner: User {
        get throws {
            try auth.require()
        }
    }
}

extension User {

    var __id: IDValue {
        get throws {
            try requireID()
        }
    }
}

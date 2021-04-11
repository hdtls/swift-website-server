import Vapor
import Fluent

final class DefaultOwnableApiImpl<T: Model & Serializing & Updatable & UserOwnable>: RestfulApiCollection where T.IDValue: LosslessStringConvertible {}

final class DefaultApiImpl<T: Model & Serializing & Updatable>: RestfulApiCollection where T.IDValue: LosslessStringConvertible {}

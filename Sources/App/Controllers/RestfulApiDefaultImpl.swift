import Vapor
import Fluent

final class DefaultOwnableApiImpl<T: Model & Serializing & Mergeable & UserOwnable>: RestfulApiCollection where T.IDValue: LosslessStringConvertible {}

final class DefaultApiImpl<T: Model & Serializing & Mergeable>: RestfulApiCollection where T.IDValue: LosslessStringConvertible {}

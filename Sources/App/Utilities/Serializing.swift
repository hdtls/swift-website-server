import Vapor
import Fluent

/// Serializing protocol provide initialze method to create new model from `SerializedObject`
/// and revert model to `SerializedObject`.
protocol Serializing {

    associatedtype SerializedObject: Content

    /// Initalize new model from `SerializedObject`.
    init(content: SerializedObject) throws

    /// Revert model to `SerializedObject`.
    func reverted() throws -> SerializedObject
}

protocol Mergeable {
    /// Merge value from other model. used to update exsit model.
    func merge(_ other: Self)
}

protocol UserOwnable: Model {
    var _$user: Parent<User> { get }
    static var uidFieldKey: FieldKey { get }
}

extension UserOwnable {
    static var uidFieldKey: FieldKey { return "user_id" }
}

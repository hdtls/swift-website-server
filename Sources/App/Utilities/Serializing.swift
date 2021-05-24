import Vapor
import Fluent

/// Serializing protocol provide initialze method to create new model from `SerializedObject`
/// and revert model to `SerializedObject`.
protocol Serializing {

    associatedtype SerializedObject: Content

    /// Initalize new model from `SerializedObject`.
    init(from dataTrasferObject: SerializedObject) throws

    /// Revert model to `SerializedObject`.
    func dataTransferObject() throws -> SerializedObject
}

protocol Updatable {
    
    associatedtype SerializedObject: Content
    /// Update value from data transfer objectl. used to update exsit model.
    func update(with dataTrasferObject: SerializedObject) throws -> Self
}

protocol UserOwnable: Model {
    var _$user: Parent<User> { get }
    static var uidFieldKey: FieldKey { get }
}

extension UserOwnable {
    static var uidFieldKey: FieldKey { return "user_id" }
}

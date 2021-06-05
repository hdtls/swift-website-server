import Vapor
import Fluent

/// Serializing protocol provide initialze method to create new model from `DTO`
/// and revert model to `DTO`.
protocol Serializing {

    associatedtype DTO: Content

    /// Initalize new model from `DTO`.
    init(from dataTrasferObject: DTO) throws

    /// Revert model to `SerializedObject`.
    func dataTransferObject() throws -> DTO
}

protocol Updatable {
    
    associatedtype DTO: Content
    /// Update value from data transfer objectl. used to update exsit model.
    func update(with dataTrasferObject: DTO) throws -> Self
}

protocol UserOwnable: Model {
    var _$user: Parent<User> { get }
    static var uidFieldKey: FieldKey { get }
}

extension UserOwnable {
    static var uidFieldKey: FieldKey { return "user_id" }
}

import Vapor

/// Bridgeable protocol provide initialze method to create new model from `DTO`
/// and revert model to `DTO`.
protocol Bridgeable {

    associatedtype DTO: Content

    /// Create new model from `DTO`.
    static func fromBridgedDTO(_ dataTransferObject: DTO) throws -> Self

    /// Revert model to `DTO`.
    func bridged() throws -> DTO
}

protocol Updatable {

    associatedtype DTO

    /// Update value from data transfer objectl. used to update exsit model.
    func update(with dataTransferObject: DTO) throws
}

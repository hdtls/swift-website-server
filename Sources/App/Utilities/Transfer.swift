import Vapor
import Fluent

/// Model protocol add some help function to quick transfer coding object to model.
protocol Transfer {
    associatedtype Coding: Content

    /// Convert model from `Coding` content.
    /// - Parameter from: Convert source.
    static func __converted(_ coding: Coding) throws -> Self

    /// Merge value from another model. used to update exsit model.
    func __merge(_ another: Self)

    /// Revert model to `Coding` type to encode to response.
    func __reverted() throws -> Coding
}

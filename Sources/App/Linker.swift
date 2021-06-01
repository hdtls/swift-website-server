import Foundation
import Fluent

final class Linker<From, To>: Fluent.Model where From: Fluent.Model, To: Fluent.Model {
    
    static var schema: String { "\(From.schema)_\(To.schema)_linkers" }
    
    @ID()
    var id: UUID?
    
    @Parent(key: "from")
    var from: From
    
    @Parent(key: "to")
    var to: To
}

import Vapor
import Fluent

final class ExpIndustrySiblings: Model {
    typealias IDValue = UUID

    static var schema: String = "exp_industry_siblings"

    @ID()
    var id: IDValue?

    @Parent(key: FieldKeys.experience.rawValue)
    var experience: Experience

    @Parent(key: FieldKeys.industry.rawValue)
    var industry: Industry

    init() {}
}

extension ExpIndustrySiblings {

    enum FieldKeys: FieldKey {
        case experience = "experience_id"
        case industry = "industry_id"
    }
}

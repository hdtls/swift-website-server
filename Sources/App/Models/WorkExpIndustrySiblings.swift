import Vapor
import Fluent

final class WorkExpIndustrySiblings: Model {
    typealias IDValue = UUID

    static var schema: String = "work_exp_industry_siblings"

    @ID()
    var id: IDValue?

    @Parent(key: FieldKeys.workExp.rawValue)
    var workExp: WorkExp

    @Parent(key: FieldKeys.industry.rawValue)
    var industry: Industry

    init() {}
}

extension WorkExpIndustrySiblings {

    enum FieldKeys: FieldKey {
        case workExp = "work_exp_id"
        case industry = "industry_id"
    }
}

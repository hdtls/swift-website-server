//===----------------------------------------------------------------------===//
//
// This source file is part of the website-backend open source project
//
// Copyright © 2020 Eli Zhang and the website-backend project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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

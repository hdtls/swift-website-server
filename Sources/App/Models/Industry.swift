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

final class Industry: Model {

    typealias IDValue = UUID

    static var schema: String = "industries"

    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.title.rawValue)
    var title: String

    @Siblings(through: WorkExpIndustrySiblings.self, from: \.$industry, to: \.$workExp)
    var workExp: [WorkExp]

    init() {}

    init(title: String) {
        self.title = title
    }
}

// MARK: FieldKeys
extension Industry {

    enum FieldKeys: FieldKey {
        case title
    }
}

extension Industry: Transfer {

    struct Coding: Content, Equatable {
        // `id` should not be nil except for creation action.
        var id: IDValue?

        // `title` can be nil except create & update new industry.
        var title: String?
    }

    static func __converted(_ coding: Coding) throws -> Industry {
        let industry = Industry.init()
        industry.id = coding.id
        industry.title = coding.title
        return industry
    }

    func __merge(_ another: Industry) {
        id = another.id
        title = another.title
    }

    func __reverted() throws -> Coding {
        try Coding.init(id: requireID(), title: title)
    }
}

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
        var title: String
    }

    static func __converted(_ coding: Coding) throws -> Industry {
        Industry.init(title: coding.title)
    }

    func __merge(_ another: Industry) {
        title = another.title
    }

    func __reverted() throws -> Coding {
        try Coding.init(id: requireID(), title: title)
    }
}

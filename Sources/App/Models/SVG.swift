//
//  SVG.swift
//  App
//
//  Created by melvyn on 6/21/20.
//

import Vapor

struct SVGPath: Codable {

    var fill: String?
    var path: String

    init(fill: String? = nil, path: String) {
        self.fill = fill
        self.path = path
    }
}

extension SVGPath: Content {}

struct SVG: Codable {
    var version: String
    var paths: [SVGPath]

    init(version: String = "1.1", paths: [SVGPath]) {
        self.version = version
        self.paths = paths
    }
}

extension SVG: Content {}

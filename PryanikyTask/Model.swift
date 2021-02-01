//
//  Data.swift
//  PryanikyTask
//
//  Created by Leonid Safronov on 29.01.2021.
//

import Foundation

struct ViewData: Codable {
    let data: [Datum]
    let view: [String]
    
    static var empty: Self {
        return ViewData(data: [], view: [])
    }
}

struct Datum: Codable {
    let name: String
    let data: InternalData
}

struct InternalData: Codable {
    let text: String?
    let url: String?
    let selectedID: Int?
    let variants: [Variant]?
    
    enum CodingKeys: String, CodingKey {
        case text, url
        case selectedID = "selectedId"
        case variants
    }
}

struct Variant: Codable {
    let id: Int
    let text: String
}


enum Status: String {
    case success = "Success"
    case fail = "Fail"
    case epmty = ""
}


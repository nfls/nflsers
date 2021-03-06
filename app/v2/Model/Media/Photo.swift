//
//  Photo.swift
//  NFLSers-iOS
//
//  Created by Qingyang Hu on 21/01/2018.
//  Copyright © 2018 胡清阳. All rights reserved.
//

import Foundation
import ObjectMapper

struct Photo: Model {
 
    init(map: Map) throws {
        self.id = try map.value("id")
        self.height = try map.value("h")
        self.width = try map.value("w")
        self.thumbUrl = MainConstant.apiEndpoint.appendingPathComponent("storage/photos/thumb").appendingPathComponent(try map.value("msrc"))
        self.hdUrl = MainConstant.apiEndpoint.appendingPathComponent("storage/photos/hd").appendingPathComponent(try map.value("src"))
        if let url: String = try? map.value("osrc") {
            self.originUrl = MainConstant.apiEndpoint.appendingPathComponent("storage/photos/origin").appendingPathComponent(url)
        } else {
            self.originUrl = nil
        }
    }
    
    let id: Int
    let height: Int
    let width: Int
    let thumbUrl: URL
    let hdUrl: URL
    let originUrl: URL?
}


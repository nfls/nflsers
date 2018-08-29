//
//  User.swift
//  NFLSers-iOS
//
//  Created by Qingyang Hu on 21/01/2018.
//  Copyright © 2018 胡清阳. All rights reserved.
//

import Foundation
import ObjectMapper

struct User: Model {
    init(map: Map) throws {
        self.id = try map.value("id")
        self.username = try map.value("username")
        self.htmlUsername = try map.value("htmlUsername")
        self.point = try map.value("point")
        self.isAdmin = try map.value("admin")
        self.isVerified = try map.value("verified")
        self.phone = try? map.value("phone")
        self.email = try? map.value("email")
        if let joinTime: String = try? map.value("joinTime") {
            self.joinTime = ISO8601DateFormatter().date(from: joinTime)
        } else {
            self.joinTime = nil
        }
        self.unreadCount = try? map.value("unreadCount")
    }
    let id: Int
    let username: String
    let htmlUsername: String
    let point: Int
    let isAdmin: Bool
    let isVerified: Bool
    let phone: String?
    let email: String?
    let joinTime: Date?
    let unreadCount: Int?
}
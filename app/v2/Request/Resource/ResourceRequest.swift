//
//  PastPaper.swift
//  NFLSers-iOS
//
//  Created by Qingyang Hu on 22/02/2018.
//  Copyright © 2018 胡清阳. All rights reserved.
//

import Foundation
import Moya

enum ResourceRequest {
    case token()
    case header()
    case shortcuts()
}

extension ResourceRequest: TargetType {
    var baseURL: URL {
        return URL(string: "https://papers.mrtunnel.club")!
    }
    
    var path: String {
        return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return WaterConstant.header
    }
}

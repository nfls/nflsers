//
//  PastPaper.swift
//  NFLSers-iOS
//
//  Created by Qingyang Hu on 22/02/2018.
//  Copyright © 2018 胡清阳. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON
import Cache
import AliyunOSSiOS

enum SchoolRequest {
    case pastpaperToken()
    case pastpaperHeader()
    case blackboardList()
    case blackboardDetail(id:String, page:Int?)
}

extension SchoolRequest: TargetType {
    var baseURL: URL {
        return URL(string: Constant.getApiUrl() + "school/")!
    }
    
    var path: String {
        switch self {
        case .pastpaperToken():
            return "pastpaper/token"
        case .pastpaperHeader():
            return "pastpaper/header"
        case .blackboardList():
            return "blackboard/list"
        case .blackboardDetail(_, _):
            return "blackboard/detail"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .pastpaperToken():
            return .requestPlain
        case .pastpaperHeader():
            return .requestPlain
        case .blackboardList():
            return .requestPlain
        case .blackboardDetail(let id, let page):
            if let page = page {
                return .requestParameters(parameters: ["id":id,"page":page], encoding: URLEncoding.default)
            } else {
                return .requestParameters(parameters: ["id":id], encoding: URLEncoding.default)
            }
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
}

class SchoolProvider:Network<SchoolRequest> {
    fileprivate var files = [File]()
    
    public func getFileList(withPath path:[String],completion: @escaping (_ files:[File]) -> Void)
    {
        
    }
    
    fileprivate func getClient(completion: @escaping (_ files:[File]) -> Void)
    {
        self.request(target: .pastpaperToken(), type: StsToken.self, success: { response in
            let token = response
            let stsTokenProvider = OSSStsTokenCredentialProvider(accessKeyId: token.accessKeyId, secretKeyId: token.accessKeySecret, securityToken: token.securityToken)
            self.requestList(OSSClient(endpoint: "https://oss-cn-shanghai.aliyuncs.com", credentialProvider: stsTokenProvider), next: nil, completion: completion)
        })
    }
    
    fileprivate func requestList(_ client:OSSClient, next:String? = nil, completion: @escaping (_ files:[File]) -> Void)
    {
        let bucket = OSSGetBucketRequest()
        bucket.bucketName = "nfls-papers"
        bucket.maxKeys = 1000
        bucket.marker = next ?? ""
        bucket.prefix = ""
        let task = client.getBucket(bucket)
        task.continue({ rsp -> Any? in
            if let t = (rsp.result as? OSSGetBucketResult) {
                if let contents = t.contents {
                    for object in contents{
                        let data = object as! [String:Any]
                        self.files.append(File(data))
                    }
                    self.requestList(client, next: (t.contents!.last as! [String:Any])["Key"] as? String, completion: completion)
                }else{
                    completion(self.files)
                }
            } else {
                print(rsp.error)
            }
            return task
        })
    }
}

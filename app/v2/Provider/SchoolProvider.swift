//
//  SchoolProvider.swift
//  NFLSers-iOS
//
//  Created by Qingyang Hu on 01/04/2018.
//  Copyright © 2018 胡清阳. All rights reserved.
//

import Foundation
import ObjectMapper
import Moya
import AliyunOSSiOS
import FileKit

class SchoolProvider:AbstractProvider<SchoolRequest> {
    //fileprivate var files = [File]()
    fileprivate var isLoaded = false
    public var path = [String]()
    fileprivate var client:OSSClient? = nil
    fileprivate let interval:TimeInterval = 0.04
    fileprivate var scheduledNextFire:Date = Date()
    
    public func getFileList(completion: @escaping (_ files:[File]) -> Void)
    {
        if let files = try? self.cache.object(ofType: [File].self, forKey: "school.pastpaper.list.cache") {
            completion(self.filter(files))
        }
        if !self.isLoaded {
            self.isLoaded = true
            self.getList(completion: completion)
        }
    }
    
    fileprivate func getAllFileListFromCache() -> [File] {
        if let files = try? self.cache.object(ofType: [File].self, forKey: "school.pastpaper.list.cache") {
            return files
        } else {
            return []
        }
        
    }
    public func getFile(file:File, progress: @escaping (_ precentage:Double) -> Void, completion: @escaping (_ succeeded:Bool) -> Void)
    {
        if file.size == 0 {
            completion(true)
        }
        if let client = client {
            let request = OSSGetObjectRequest()
            request.bucketName = "nfls-papers"
            request.objectKey = file.name
            request.downloadProgress = { bytesWritten, totalBytesWritten, bytesExpectedToWritten in
                if(Date() > self.scheduledNextFire){
                    self.scheduledNextFire = Date() + self.interval
                    progress(Double(totalBytesWritten)/Double(bytesExpectedToWritten))
                }
            }
            let task = client.getObject(request)
            task.continue({ task -> Any? in
                if let error = task.error {
                    print(error)
                }else{
                    
                    let result = task.result as! OSSGetObjectResult
                    do {
                        let path = Path.userDocuments + "download" + self.getPath()
                        try path.createDirectory(withIntermediateDirectories: true)
                        try result.downloadedData |> DataFile(path: path + file.filename)
                        completion(true)
                    } catch let error {
                        self.notifier.showNetworkError(AbstractError(status: 1001, message: error.localizedDescription))
                        completion(false)
                    }
                }
                return task
            })
        } else {
            self.notifier.showNetworkError(nil)
            completion(false)
        }
    }
    
    public func getFiles(files:[File], progress: @escaping (_ total:Int, _ current:Int, _ file: File) -> Void, fileProgress: @escaping (_ precentage:Double) -> Void, completion: @escaping (_ succeeded:Bool) -> Void)
    {
        let fileList = self.getAllFileListFromCache()
        var toDownload = [File]()
        for file in files {
            let f = fileList.filter({ list -> Bool in
                return list.name.hasPrefix(file.name)
            })
            toDownload.append(contentsOf: f)
        }
        if(files.count == 0){
            return
        }
        self.getFileWithList(files: toDownload, index: 0, progress: progress, fileProgress: fileProgress, completion: completion)
    }
    
    fileprivate func getFileWithList(files:[File], index:Int, progress: @escaping (_ total:Int, _ current:Int, _ file: File) -> Void, fileProgress: @escaping (_ precentage:Double) -> Void, completion: @escaping (_ succeeded:Bool) -> Void)
    {
        if(index >= files.count){
            completion(true)
        }else{
            progress(files.count, index + 1, files[index])
            self.getFile(file: files[index], progress: fileProgress) { status in
                if status {
                    self.getFileWithList(files: files, index: index + 1, progress: progress, fileProgress: fileProgress, completion: completion)
                }else{
                    completion(false)
                }
            }
        }
    }
    
    fileprivate func getList(completion: @escaping (_ files:[File]) -> Void)
    {
        self.notifier.showInfo("正在后台刷新文件列表，操作完成后列表将自动刷新")
        self.request(target: .pastpaperToken(), type: StsToken.self, success: { response in
            let token = response
            let stsTokenProvider = OSSStsTokenCredentialProvider(accessKeyId: token.accessKeyId, secretKeyId: token.accessKeySecret, securityToken: token.securityToken)
            self.client = OSSClient(endpoint: "https://oss-cn-shanghai.aliyuncs.com", credentialProvider: stsTokenProvider)
            self.requestList(result:[], next: nil, completion: completion)
        }, error: { _ in
            self.notifier.showInfo("您尚未完成实名认证，请先在首页上完成相关认证操作！")
        })
    }
    
    fileprivate func requestList(result:[File] = [],next:String? = nil, completion: @escaping (_ files:[File]) -> Void)
    {
        if let client = client {
            var files = result
            let bucket = OSSGetBucketRequest()
            bucket.bucketName = "nfls-papers"
            bucket.maxKeys = 1000
            bucket.marker = next ?? ""
            let task = client.getBucket(bucket)
            task.continue({ rsp -> Any? in
                if let t = (rsp.result as? OSSGetBucketResult) {
                    if let contents = t.contents {
                        for object in contents{
                            let data = object as! [String:Any]
                            files.append(File(data))
                        }
                        self.requestList(result: files, next: (t.contents!.last as! [String:Any])["Key"] as? String, completion: completion)
                    }else{
                        try? self.cache.setObject(files, forKey: "school.pastpaper.list.cache")
                        completion(self.filter(files))
                    }
                } else {
                    print(rsp.error)
                }
                return task
            })
        }
        
    }
    
    fileprivate func filter(_ files:[File]) -> [File]
    {
        let realPath = self.getPath()
        var files =  files.filter({ file -> Bool in
            return (file.name.components(separatedBy: "/").count == path.count + 1) && file.name.hasPrefix(realPath)
        })
        if path.contains("Past Papers") && files.filter({$0.filename.contains(".pdf")}).count == 0 {
            files = files.reversed()
        }
        if(path.count > 0){
            files.insert(File(specialAction: "@Back", withName: "返回"), at: 0)
        }
        return files
    }
    
    fileprivate func getPath() -> String {
        return (path as NSArray).componentsJoined(by: "/")
    }
}
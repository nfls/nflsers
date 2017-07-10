//
//  NotificationView.swift
//  NFLSers-iOS
//
//  Created by hqy on 2017/6/26.
//  Copyright © 2017年 胡清阳. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
class NotificationViewController:UIViewController, UITableViewDataSource, UITableViewDelegate{
    let ID = "Cell"
    var count = 0
    var titles = [String]()
    var types = [String]()
    var details = [String]()
    var times = [String]()
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.register(NotificationCell.self, forCellReuseIdentifier: ID)
                getNotificationData()
    }
    
    func getNotificationData(){
        let headers: HTTPHeaders = [
            "Cookie" : "token=" + "953176462068c12df3d57481a67b7626dff0b9a55eaed9be2b0045ace006e537"
        ]
        Alamofire.request("https://api.nfls.io/center/systemMessage", headers: headers).responseJSON{ response in
            switch response.result{
            case .success(let json):
                //dump(json)
                if(((json as! [String:AnyObject])["code"] as! Int)==200){
                    let messages = (json as! [String:AnyObject])["info"] as! NSArray
                    for message in messages {
                        var data = message as! [String:String]
                        self.count += 1
                        self.details.append(data["detail"]!)
                        self.times.append(data["time"]!)
                        self.titles.append(data["title"]!)
                        self.types.append(data["type"]!)
                    }
                    self.details.reverse()
                    self.times.reverse()
                    self.titles.reverse()
                    self.types.reverse()
                    DispatchQueue.main.async{
                        self.tableview.dataSource = self
                        self.tableview.delegate = self
                        self.tableview.reloadData()
                    }
                }
                break
            default:
                break
                /*
                self.showAlert(false)
                break
 */
            }
        }

    }
    
    func addNotification(){
        
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: ID, for: indexPath as IndexPath)
        cell.textLabel!.text = "\(types[indexPath.row]) - \(titles[indexPath.row])"
        cell.detailTextLabel!.text = "\(times[indexPath.row])\n\(details[indexPath.row])"
        cell.detailTextLabel!.lineBreakMode = .byWordWrapping
        cell.detailTextLabel!.numberOfLines = 0
        cell.detailTextLabel!.sizeToFit()
        cell.sizeToFit()

        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        //let cell = tableView.dequeueReusableCell(withIdentifier: ID)
        //return cell!.textLabel!.frame.height + cell!.detailTextLabel!.frame.height
        return 100
    }
}

class NotificationCell:UITableViewCell{
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        //self.setUpUI()
    }
}

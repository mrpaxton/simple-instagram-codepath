//
//  ViewController.swift
//  SimpleInstagram
//
//  Created by Sarn Wattanasri on 1/20/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var medias: [NSDictionary]!
    
    let CellIdentifier = "TableViewCell"
    let HeaderViewIdentifier = "TableViewHeaderView"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(UITableViewHeaderFooterView.self , forHeaderFooterViewReuseIdentifier: HeaderViewIdentifier)
        
        //set a row height to the table view
        tableView.rowHeight = 320
        
        //use a closure to call the instagram API in the callInstagramAPI() method
        callInstagramAPI{ (photos : [NSDictionary]?) -> () in
            self.medias = photos
            self.tableView.reloadData()
        }
    }
    
    func delay(delay:Double, closure: () -> ()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure
        )
    }
    
    func callInstagramAPI( success: ([NSDictionary]?) -> () ) {
        let clientId = "e05c462ebd86446ea48a5af73769b602"
        let url = NSURL(string:"https://api.instagram.com/v1/media/popular?client_id=\(clientId)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.delay(
                                3.0,
                                closure: {
                                    MBProgressHUD.hideHUDForView(self.view, animated: true )
                                }
                            )
                            
                            success( responseDictionary["data"] as? [NSDictionary] )
                    }
                }
        });
        task.resume()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return medias?.count ?? 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        headerView.backgroundColor = UIColor(white: 1, alpha: 0.9)
        let profileView = makeProfileView(section)
        headerView.addSubview(profileView!)
        return headerView
    }
    
    func makeProfileView(section: Int) -> UIView? {
        let profileView = UIView(frame: CGRect(x: 0, y: -5, width: 320, height: 50))
        let profileLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 320, height: 50))
        profileLabel.text = medias[section].valueForKeyPath("user.username") as? String
        let profileImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        profileView.clipsToBounds = true
        profileView.layer.cornerRadius = 5;
        profileView.layer.borderColor = UIColor(white: 0.7, alpha: 0.8).CGColor
        
        // Use the section number to get the right URL
        let imageURL = NSURL(string: medias[section].valueForKeyPath("user.profile_picture") as! String )
        profileImageView.setImageWithURL( imageURL! )
        profileView.addSubview(profileImageView)
        profileView.addSubview(profileLabel)
        
        return profileView
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MediaCell", forIndexPath: indexPath ) as? MediaCell
        let imageURL = NSURL( string: medias[indexPath.section].valueForKeyPath("images.standard_resolution.url") as! String)
        cell?.feedImageView.setImageWithURL(imageURL!)
        return cell!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


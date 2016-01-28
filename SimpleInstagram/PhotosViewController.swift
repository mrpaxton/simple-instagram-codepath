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

class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var medias: [NSDictionary]!
    
    let CellIdentifier = "TableViewCell"
    let HeaderViewIdentifier = "TableViewHeaderView"
    
    //flag for infinite scroll
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    // property for refresh control
    var refreshControl: UIRefreshControl!
    
    
    // pull to refresh
    func pullToRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func onRefresh(){
        delay(2, closure: {
            self.refreshControl.endRefreshing()
        })
    }
    
    
    //infinite scroll
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !isMoreDataLoading {
            //calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            //when the user has scrolled past the threshold, start requesting
            if scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging {
                isMoreDataLoading = true
                
                let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                //load more data
                loadMoreData()
            }
        }
    }
    
    func loadMoreData() {
        //TODO: refactor the setups for the request later
        let clientId = "e05c462ebd86446ea48a5af73769b602"
        let url = NSURL(string:"https://api.instagram.com/v1/media/popular?client_id=\(clientId)")
        let request = NSURLRequest(URL: url!)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                //update the flag
                self.isMoreDataLoading = false
                
                //stop the loading indicator
                self.loadingMoreView!.stopAnimating()
                
                //use the new data to update the data source
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                        self.medias = responseDictionary["data"] as? [NSDictionary]
                    }
                }
                
                //reload the table view because we have new data
                self.tableView.reloadData()
            }
        )
        task.resume()
    }
    
    func setupInfiniteScrollView() {
        let frame = CGRectMake(0, tableView.contentSize.height,
            tableView.bounds.size.width,
            InfiniteScrollActivityView.defaultHeight
        )
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.hidden = true
        tableView.addSubview( loadingMoreView! )
        
        var insets = tableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        tableView.contentInset = insets
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(UITableViewHeaderFooterView.self , forHeaderFooterViewReuseIdentifier: HeaderViewIdentifier)
        
        //set a row height to the table view
        tableView.rowHeight = 320
        
        // call the pull to refresh control function
        pullToRefreshControl()
        
        //setup the infnite scroll view
        setupInfiniteScrollView()
        
        
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
    
    func fadeInImageOnNetworkCall<T: UIView>(request: NSURLRequest, placeholderImage: UIImage?, duration: NSTimeInterval, cell: T ) -> T? {
        if let mediaCell = cell as? MediaCell {
            mediaCell.feedImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
                UIView.transitionWithView(mediaCell.feedImageView, duration: duration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { mediaCell.feedImageView.image = imageData }, completion: nil   )
                }, failure: nil)
            return mediaCell as? T
        }
        return nil
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
        let request = NSURLRequest(URL: imageURL!)
        let placeholderImage = UIImage(named: "vintage-camera")
        let mediaCell = fadeInImageOnNetworkCall(request, placeholderImage: placeholderImage, duration: 0.20, cell: cell!)
        //cell?.feedImageView.setImageWithURL(imageURL!)
        return mediaCell!
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! PhotoDetailsViewController
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        vc.photoURL = NSURL( string: medias[indexPath!.section].valueForKeyPath("images.standard_resolution.url") as! String)
    }

}


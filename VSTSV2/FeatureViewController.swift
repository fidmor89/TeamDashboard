//
//  FeatureViewController.swift
//  VSTSV2
//
//  Created by Giorgio Andre Balconi Taracena on 03/22/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//
//    The MIT License (MIT)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import UIKit
import MBProgressHUD
import SwiftyJSON

class FeatureViewController: UITableViewController {
    
    var features : [String] = []
    var displayingLoadingNotification = false
    var defaultWidth: CGFloat = 0.0
    
    func getFeatures(){
        if (StateManager.SharedInstance.team.Project != "" && StateManager.SharedInstance.team.name != ""){
            RestApiManager.sharedInstance.getActiveFeatures(StateManager.SharedInstance.team, onCompletion:  {json, result in
                
                let jsonOBJCollections = json["workItems"]             //get json with features
                
                if jsonOBJCollections.isEmpty{
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                
                jsonOBJCollections.forEach({ ( content: (String, JSON)) -> () in
                    
                    
                    let featureUrl = content.1["url"].string as String! ?? ""
                    
                    RestApiManager.sharedInstance.getFeature(featureUrl, onCompletion: { json1, result in
                        let fields = json1["fields"]
                        let name = fields["System.Title"].string as String! ?? ""
                        self.features.append(name)
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView?.reloadData()
                            
                            let heightValue = min(CGFloat(44 * self.features.count), UIScreen.mainScreen().bounds.height)
                            self.preferredContentSize.height = heightValue
                            
                            if self.features.isEmpty{
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        })
                    })
                })//End foreach
                
            })
        }else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // Overridable methods
    override func viewDidLoad() {
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"

        
        self.tableView.separatorColor = UIColor.clearColor()
        self.tableView?.alwaysBounceVertical = false            //If projects fit in the window there should be no scroll.
        
        let backgroundImage = UIImage(named: "background")
        let imageView = UIImageView(image: backgroundImage)
        if UIDevice().isBlurSupported() &&  !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = imageView.bounds
            imageView.addSubview(blurView)
        }
        self.tableView.backgroundView = imageView
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Initial size
        self.preferredContentSize.height = CGFloat(105)
        self.defaultWidth = self.preferredContentSize.width
        self.preferredContentSize.width = CGFloat(105)

        getFeatures()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
    }
    
    // Selected a row
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Return the number of rows in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.features.count
    }
    
    // Fill table with information about teams
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)         //Hide loading
        
        var cell = self.tableView!.dequeueReusableCellWithIdentifier("FeatureCell") as? WorkItemCell
        if cell == nil {
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "FeatureCell")
        }
        
        let feature = self.features[indexPath.row]
        cell!.textLabel?.text = feature
        cell?.textLabel?.textColor = UIColor.whiteColor()
        
        cell?.textLabel?.backgroundColor = UIColor.clearColor()
        cell?.contentView.backgroundColor = UIColor.blackColor()
        cell?.contentView.layer.cornerRadius = 10
        cell?.contentView.layer.masksToBounds = true
        cell?.contentView.alpha = 0.75
        
        cell?.backgroundColor = UIColor.clearColor()
        
        self.preferredContentSize.width = self.defaultWidth
        return cell!
    }
}
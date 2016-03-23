//
//  AboutViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 3/23/16.
//  Copyright © 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
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

class AboutViewController: UITableViewController {
    
    var credits: NSMutableArray = []
    
    override func viewWillAppear(animated: Bool) {
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Credits", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            credits =  dict["PreferenceSpecifiers"] as! NSMutableArray
            //            credits.forEach({
            //                print($0["Title"])
            //                print($0["FooterText"])
            //            })
        }
        
        self.tableView?.alwaysBounceVertical = false
        
        //add header and footer to remove the extra separator lines
        let v: UIView = UIView()
        v.backgroundColor = UIColor.clearColor()
        self.tableView.tableHeaderView = v
        self.tableView.tableFooterView = v
        
        super.viewWillAppear(animated)
    }
    
    //Cells
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1        //Displaying one license per section.
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.tableView!.dequeueReusableCellWithIdentifier("CreditCell") as UITableViewCell!
        if cell == nil {
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "CreditCell")
        }
        
        cell!.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        cell!.textLabel?.numberOfLines = 0
        cell!.textLabel?.text = credits[indexPath.section]["FooterText"] as? String
        
        return cell!
    }
    
    //Make the Cell Grow until needed to display al of its contents.
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    //End Cells
    
    //Sections
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return credits.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return credits[section]["Title"] as? String
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40);
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.font = UIFont.systemFontOfSize(30.0)
        }
    }
    //End Sections
    
    
}
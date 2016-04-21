//
//  SecondViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/18/16.
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

import UIKit
import MBProgressHUD

class SecondViewController: UIViewController {
    
    
    @IBOutlet var parentView: UIView!
    @IBOutlet var viewSection: [UIView]!
    @IBOutlet weak var lowerLeftImageView: UIImageView!
    @IBOutlet weak var lowerRightImageView: UIImageView!
    @IBOutlet weak var upperRightImageView: UIImageView!
    @IBOutlet weak var upperLeftImageView: UIImageView!
    
    var everythingOk = true
    
    override func viewDidLoad() {
        
        let backgroundImage = UIImage(named: "background")
        let imageView = UIImageView(image: backgroundImage)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        blurView.frame = imageView.bounds
        imageView.addSubview(blurView)
        self.parentView.addSubview(imageView)
        
        for view in self.viewSection{
            view.layer.cornerRadius = 10                                    //Round corners in sections
            view.layer.masksToBounds = true                                 //Keep child-views within the parent-view
            view.alpha = 0.75                                               //Semi transparent sections
            view.backgroundColor = UIColor.whiteColor()                     //White sections
            self.parentView.bringSubviewToFront(view)
        }
        
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        everythingOk = true
        drawVelocityChart()
        drawChartWithCategory("Microsoft.RequirementCategory", chart:self.upperRightImageView)
        drawChartWithCategory("Microsoft.FeatureCategory", chart:self.lowerLeftImageView)
        drawChartWithCategory("Microsoft.EpicCategory", chart:self.lowerRightImageView)
        
        createTapGesture("velocityTap", UIControl: self.lowerLeftImageView)
        createTapGesture("RequirementsTap", UIControl: self.lowerRightImageView)
        createTapGesture("FeaturesTap", UIControl: self.upperRightImageView)
        createTapGesture("EpicsTap", UIControl: self.upperLeftImageView)

        super.viewWillAppear(animated)
    }

    func velocityTap() {
        print("Single Tap on velocity imageview")
    }
    func RequirementsTap() {
        print("Single Tap on Requirements imageview")
    }
    func FeaturesTap() {
        print("Single Tap on Features imageview")
    }
    func EpicsTap() {
        print("Single Tap on Epics imageview")
    }
    
    override func viewDidAppear(animated: Bool) {
        if !everythingOk{
            let alert = UIAlertController(title: "Missing Graph", message: "Enable this feature in VSTS/TFS to display the graph, contact your VSTS/TFS admin.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        // Dispose of any resources that can be recreated.
    }
    
    func drawVelocityChart(){
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.upperLeftImageView, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        
        if let imageURL = RestApiManager.sharedInstance.getVelocityURL(StateManager.SharedInstance.team){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        if let image = UIImage(data: data!){
                            self.upperLeftImageView.setImageWithAnimation(image)
                        }
                    }
                    MBProgressHUD.hideAllHUDsForView(self.upperLeftImageView, animated: true)
            })
        }else{
            MBProgressHUD.hideAllHUDsForView(self.upperLeftImageView, animated: true)
            self.upperLeftImageView.setImageWithAnimation(UIImage(named: "sadFace")!)
            everythingOk = false
        }
    }
    
    func drawChartWithCategory(Category:String, chart:UIImageView){
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(chart, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        if let imageURL = RestApiManager.sharedInstance.getComulativeFlow(StateManager.SharedInstance.team, Category: Category){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        if let image = UIImage(data: data!){
                            chart.setImageWithAnimation(image)
                        }
                    }
                    MBProgressHUD.hideAllHUDsForView(chart, animated: true)
            })
        }else{
            MBProgressHUD.hideAllHUDsForView(chart, animated: true)
            chart.setImageWithAnimation(UIImage(named: "sadFace")!)
            everythingOk = false
        }
    }
}


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
import Agrume

class SecondViewController: UIViewController {
    
    
    @IBOutlet weak var backlogItem: UILabel!
    @IBOutlet weak var EpicTitle: UILabel!
    @IBOutlet weak var FeaturesTitle: UILabel!
    @IBOutlet weak var VelocityTitle: UILabel!
    
    @IBOutlet var parentView: UIView!
    @IBOutlet var viewSection: [UIView]!
    @IBOutlet weak var lowerLeftImageView: UIImageView!
    @IBOutlet weak var lowerRightImageView: UIImageView!
    @IBOutlet weak var upperRightImageView: UIImageView!
    @IBOutlet weak var upperLeftImageView: UIImageView!
    
    var velocity: UIImage? = nil
    var Requirements: UIImage? = nil
    var Features: UIImage? = nil
    var Epics: UIImage? = nil
    
    var actualTeamID = ""
    
    var everythingOk = true
    
    override func viewDidLoad() {
        
        let backgroundImage = UIImage(named: "background")
        let imageView = UIImageView(image: backgroundImage)
        if UIDevice().isBlurSupported() &&  !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = imageView.bounds
            imageView.addSubview(blurView)
            self.parentView.addSubview(imageView)
        }else{
            self.parentView.addSubview(UIImageView(image: UIImage(named: "preBlurredBackground")))
        }
        
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
        
        if actualTeamID != StateManager.SharedInstance.team.id{
            self.clearImages()
            actualTeamID = StateManager.SharedInstance.team.id
        }
        
        dispatch_async(GlobalUserInteractiveQueue){
            if self.velocity == nil { self.drawVelocityChart() }
        }
        dispatch_async(GlobalUserInteractiveQueue){
            if self.Requirements == nil { self.drawChartWithCategory("Microsoft.RequirementCategory", chart:self.upperRightImageView) }
        }
        dispatch_async(GlobalUserInteractiveQueue){
            if self.Features == nil { self.drawChartWithCategory("Microsoft.FeatureCategory", chart:self.lowerLeftImageView) }
        }
        dispatch_async(GlobalUserInteractiveQueue){
            if self.Epics == nil { self.drawChartWithCategory("Microsoft.EpicCategory", chart:self.lowerRightImageView) }
        }
        createTapGesture(#selector(SecondViewController.FeaturesTap), UIControl: self.lowerLeftImageView)
        createTapGesture(#selector(SecondViewController.EpicsTap), UIControl: self.lowerRightImageView)
        createTapGesture(#selector(SecondViewController.RequirementsTap), UIControl: self.upperRightImageView)
        createTapGesture(#selector(SecondViewController.velocityTap), UIControl: self.upperLeftImageView)
        
        super.viewWillAppear(animated)
    }
    
    func displayFullScreenImage(image: UIImage){
        //capture current background
        let window: UIWindow! = UIApplication.sharedApplication().keyWindow
        let windowImage = window.capture()
        
        //Initialize agrume
        let agrume = Agrume(image: image)
        agrume.showFrom(self, windowImage: windowImage)
        
    }
    
    func velocityTap() {
        if let image = velocity{
            self.displayFullScreenImage((image))
        }
    }
    func RequirementsTap() {
        if let image = Requirements{
            self.displayFullScreenImage((image))
        }
    }
    func FeaturesTap() {
        if let image = Features{
            self.displayFullScreenImage((image))
        }
    }
    func EpicsTap() {
        if let image = Epics{
            self.displayFullScreenImage((image))
        }
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
        self.clearImages()
        super.didReceiveMemoryWarning()
    }
    
    func clearImages(){
        velocity = nil
        Requirements = nil
        Features = nil
        Epics = nil
    }
    
    func drawVelocityChart(){
        
        dispatch_async(GlobalMainQueue){
            let loadingNotification = MBProgressHUD.showHUDAddedTo(self.upperLeftImageView, animated: true)
            loadingNotification.mode = MBProgressHUDMode.Indeterminate
            loadingNotification.labelText = "Loading"
        }
        
        if let imageURL = RestApiManager.sharedInstance.getVelocityURL(StateManager.SharedInstance.team){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        if let image = UIImage(data: data!){
                            self.upperLeftImageView.setImageWithAnimation(image)
                            self.saveImageWithCategory("", image: image, Chart: self.upperLeftImageView)
                        }
                    }
                    dispatch_async(GlobalMainQueue){
                        MBProgressHUD.hideAllHUDsForView(self.upperLeftImageView, animated: true)
                    }
            })
        }else{
            dispatch_async(GlobalMainQueue){
                MBProgressHUD.hideAllHUDsForView(self.upperLeftImageView, animated: true)
                self.upperLeftImageView.setImageWithAnimation(UIImage(named: "sadFace")!)
                self.everythingOk = false
            }
        }
    }
    
    func drawChartWithCategory(Category:String, chart:UIImageView){
        dispatch_async(GlobalMainQueue){
            let loadingNotification = MBProgressHUD.showHUDAddedTo(chart, animated: true)
            loadingNotification.mode = MBProgressHUDMode.Indeterminate
            loadingNotification.labelText = "Loading"
        }
        if let imageURL = RestApiManager.sharedInstance.getComulativeFlow(StateManager.SharedInstance.team, Category: Category){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        if let image = UIImage(data: data!){
                            chart.setImageWithAnimation(image)
                            self.saveImageWithCategory(Category, image: image, Chart: chart)
                        }
                    }
                    dispatch_async(GlobalMainQueue){
                        MBProgressHUD.hideAllHUDsForView(chart, animated: true)
                    }
            })
        }else{
            dispatch_async(GlobalMainQueue){
                MBProgressHUD.hideAllHUDsForView(chart, animated: true)
                chart.setImageWithAnimation(UIImage(named: "sadFace")!)
                self.everythingOk = false
            }
        }
    }
    
    func saveImageWithCategory(Category: String, image: UIImage, Chart: UIImageView){
        switch Category{
        case "Microsoft.RequirementCategory":
            self.Requirements = image
            Chart.bringSubviewToFront(self.backlogItem)
        case "Microsoft.FeatureCategory":
            self.Features = image
            Chart.bringSubviewToFront(self.FeaturesTitle)
        case "Microsoft.EpicCategory":
            self.Epics = image
            Chart.bringSubviewToFront(self.EpicTitle)
        default:
            self.velocity = image
            Chart.bringSubviewToFront(self.VelocityTitle)
            
        }
    }
    
}


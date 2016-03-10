//
//  SecondViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/18/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    
    @IBOutlet var parentView: UIView!
    @IBOutlet var viewSection: [UIView]!
    @IBOutlet weak var lowerLeftImageView: UIImageView!
    @IBOutlet weak var lowerRightImageView: UIImageView!
    @IBOutlet weak var upperRightImageView: UIImageView!
    @IBOutlet weak var upperLeftImageView: UIImageView!
    
    override func viewDidLoad() {
        
        let backgroud:UIColor = UIColor(patternImage: UIImage(named: "background")!)        //Create a color based on the backgroud image
        self.parentView.backgroundColor = backgroud                                         //set backgroud
        
        for i in 0...self.viewSection.count-1{
            self.viewSection[i].layer.cornerRadius = 10                                      //Round corners in sections
            self.viewSection[i].layer.masksToBounds = true                                  //Keep child-views within the parent-view
            self.viewSection[i].alpha = 0.75                                                //Semi transparent sections
            self.viewSection[i].backgroundColor = UIColor.whiteColor()                      //White sections
        }
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        drawVelocityChart()
        drawChartWithCategory("Microsoft.RequirementCategory", chart:self.upperRightImageView)
        drawChartWithCategory("Microsoft.FeatureCategory", chart:self.lowerLeftImageView)
        drawChartWithCategory("Microsoft.EpicCategory", chart:self.lowerRightImageView)
        
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        // Dispose of any resources that can be recreated.
    }
    
    func drawVelocityChart(){
        if let imageURL = RestApiManager.sharedInstance.getVelocityURL(StateManager.SharedInstance.team){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        self.upperLeftImageView.image = UIImage(data: data!)
                    }
            })
        }else{
            print("Invalid image URL")
        }
    }
    
    func drawChartWithCategory(Category:String, chart:UIImageView){
        if let imageURL = RestApiManager.sharedInstance.getComulativeFlow(StateManager.SharedInstance.team, Category: Category){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        chart.image = UIImage(data: data!)
                    }
            })
        }else{
            print("Invalid image URL")
        }
    }
}


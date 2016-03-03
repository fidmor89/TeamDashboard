//
//  SecondViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/18/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    @IBOutlet weak var lowerLeftImageView: UIImageView!
    @IBOutlet weak var lowerRightImageView: UIImageView!
    @IBOutlet weak var upperRightImageView: UIImageView!
    @IBOutlet weak var upperLeftImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadVelocity()
        loadComulativeFlow("Microsoft.RequirementCategory",chart:self.upperRightImageView)
        loadComulativeFlow("Microsoft.FeatureCategory",chart:self.lowerLeftImageView)
        loadComulativeFlow("Microsoft.EpicCategory",chart:self.lowerRightImageView)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        // Dispose of any resources that can be recreated.
    }
    func loadVelocity()
    {
        if let imageURL = RestApiManager.sharedInstance.getVelocity(StateManager.SharedInstance.team){
            
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
    func loadComulativeFlow(category:String,chart:UIImageView)
    {
        if let imageURL = RestApiManager.sharedInstance.getComulativeFlow(StateManager.SharedInstance.team, category: category){
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


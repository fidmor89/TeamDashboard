//
//  LoginController.swift
//  TFS
//
//  Created by Fidel Esteban Morales Cifuentes on 10/3/15.
//  Copyright (c) 2015 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import MBProgressHUD

class LoginController: UIViewController {
    
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signedInSwitch: UISwitch!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        RestApiManager.sharedInstance.initialize()

        if (KeychainWrapper.hasValueForKey("credentials"))
        {
            
            let source = KeychainWrapper.stringForKey("credentials")
            
            let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.Indeterminate
            loadingNotification.labelText = "Loading"
            
            var err:NSError?
            var obj:AnyObject? = NSJSONSerialization.JSONObjectWithData(source!.dataUsingEncoding(NSUTF8StringEncoding)!, options:nil, error:&err)
            
            if let items = obj as? NSArray {
                
                let itemDict:AnyObject = items[0]
                
                RestApiManager.sharedInstance.baseURL = itemDict.valueForKey("baseUrl") as! String
                RestApiManager.sharedInstance.usr = itemDict.objectForKey("user") as! String
                RestApiManager.sharedInstance.pw = itemDict.objectForKey("password") as! String
                
                //Test that parameters are still valid.
                RestApiManager.sharedInstance.validateAuthorization { auth in
                    if(auth){
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            self.performSegueToLogin()
                            
                        }
                    }else{
                        println("auth failed")
                        dispatch_async(dispatch_get_main_queue(), {                                         //run in the main GUI thread
                            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        })
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone  {
//            vsoImage.hidden = true                          //hide bottom image if user is on iphone
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onLoginButtonTouchDown(sender: AnyObject) {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        
        //Pass parameters to RestApiManager
        RestApiManager.sharedInstance.baseURL = self.serverTextField.text
        RestApiManager.sharedInstance.usr = self.userTextField.text
        RestApiManager.sharedInstance.pw = self.passwordTextField.text
        
        //Test conection
        RestApiManager.sharedInstance.validateAuthorization { auth in
            
            if(auth){
                println("auth ok")
                if (self.signedInSwitch.on)
                {
                    var credentials = "[{"
                    credentials += "\"baseUrl\": \"" + self.serverTextField.text + "\","
                    credentials += "\"user\": \"" + self.userTextField.text + "\","
                    credentials += "\"password\": \"" + self.passwordTextField.text + "\""
                    credentials += "}]"
                    KeychainWrapper.setString(credentials,forKey:"credentials")
                }
                
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.performSegueToLogin()
                }
            }else{
                println("auth failed")
                dispatch_async(dispatch_get_main_queue(), {                                         //run in the main GUI thread
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                })
            }
        }
        
    }
    
    func performSegueToLogin() -> Void{
        //Get ViewController
        let dashboardController = self.storyboard!.instantiateViewControllerWithIdentifier("Dashboard") as! UITabBarController
 
        //Dislpay the view controller
        self.presentViewController(dashboardController, animated: true, completion: nil)
    }
}


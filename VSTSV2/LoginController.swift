//
//  LoginController.swift
//  TFS
//
//  Created by Fidel Esteban Morales Cifuentes on 10/3/15.
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
import SwiftyJSON
import MBProgressHUD

class LoginController: UIViewController {
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signedInSwitch: UISwitch!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        RestApiManager.sharedInstance.initialize()
        
        if (KeychainWrapper.hasValueForKey("credentials"))
        {
            
            let source = KeychainWrapper.stringForKey("credentials")
            
            let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.Indeterminate
            loadingNotification.labelText = "Loading"
            
            var obj:AnyObject?
            do {
                obj = try NSJSONSerialization.JSONObjectWithData(source!.dataUsingEncoding(NSUTF8StringEncoding)!, options:[])
            } catch _ as NSError {
                obj = nil
            }
            
            if let items = obj as? NSArray {
                
                let itemDict:AnyObject = items[0]
                
                //Save information
                RestApiManager.sharedInstance.baseURL = itemDict.valueForKey("baseUrl") as! String
                RestApiManager.sharedInstance.usr = itemDict.objectForKey("user") as! String
                RestApiManager.sharedInstance.pw = itemDict.objectForKey("password") as! String
                
                //Test that parameters are still valid.
                valitateLogin()
            }
        }
    }
    
    override func viewDidLoad() {
        
        let backgroundImage = UIImage(named: "background")
        
        let imageView = UIImageView(image: backgroundImage)

//        add blur effect if supported
        if UIDevice().isBlurSupported() &&  !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = imageView.bounds
            imageView.addSubview(blurView)
            self.parentView.addSubview(imageView)
        }else{
            self.parentView.addSubview(UIImageView(image: UIImage(named: "preBlurredBackground")))
        }

//        let filePath = NSBundle.mainBundle().pathForResource("squaresAnimated", ofType: "gif")
//        let gif = NSData(contentsOfFile: filePath!)
//        
//        let webViewBG = UIWebView(frame: self.view.frame)
//        webViewBG.loadData(gif!, MIMEType: "image/gif", textEncodingName: String(), baseURL: NSURL())
//        webViewBG.userInteractionEnabled = false;
//        self.parentView.addSubview(webViewBG)

        
        
        self.parentView.bringSubviewToFront(self.titleView)
        self.parentView.bringSubviewToFront(self.loginView)
        
        self.loginView.backgroundColor = UIColor.blackColor()
        self.loginView.layer.cornerRadius = 10
        self.loginView.layer.masksToBounds = true
        self.loginView.alpha = 0.75
        
        self.titleView.backgroundColor = UIColor.blackColor()
        self.titleView.layer.cornerRadius = 10
        self.titleView.layer.masksToBounds = true
        self.titleView.alpha = 0.75
        
        self.signInButton.layer.cornerRadius = 5
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onLoginButtonTouchDown(sender: AnyObject) {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        
        //Pass parameters to RestApiManager
        RestApiManager.sharedInstance.baseURL = self.serverTextField.text!
        RestApiManager.sharedInstance.usr = self.userTextField.text!
        RestApiManager.sharedInstance.pw = self.passwordTextField.text!
        
        //Test conection
        RestApiManager.sharedInstance.validateAuthorization { auth in
            
            if(auth.0){
                print("auth ok")
                if (self.signedInSwitch.on)
                {
                    var credentials = "[{"
                    credentials += "\"baseUrl\": \"" + self.serverTextField.text! + "\","
                    credentials += "\"user\": \"" + self.userTextField.text! + "\","
                    credentials += "\"password\": \"" + self.passwordTextField.text! + "\""
                    credentials += "}]"
                    KeychainWrapper.setString(credentials,forKey:"credentials")
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.performSegueToLogin()
                }
            }else{
                print(auth.1)
                dispatch_async(dispatch_get_main_queue(), {                                         //run in the main GUI thread
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.alert("Login Failed", message: auth.1)
                })
            }
        }
        
    }
    
    func valitateLogin(){
        RestApiManager.sharedInstance.validateAuthorization { auth in
            if(auth.0){
                print("auth ok")
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.performSegueToLogin()
                }
            }else{
                print(auth.1)
                dispatch_async(dispatch_get_main_queue(), {                                         //run in the main GUI thread
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.alert("Login Failed", message: auth.1)
                })
            }
        }
        
    }
    
    func alert(title: String, message: String) {
        if let _: AnyClass = NSClassFromString("UIAlertController") { // iOS 8
            let myAlert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            myAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(myAlert, animated: true, completion: nil)
        } else { // iOS 7
            let alert: UIAlertView = UIAlertView()
            alert.delegate = self
            
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle("OK")
            
            alert.show()
        }
    }
    
    func performSegueToLogin() -> Void{
        //Get ViewController
        let dashboardController = self.storyboard!.instantiateViewControllerWithIdentifier("Dashboard") as! UITabBarController
        
        //Dislpay the view controller
        self.presentViewController(dashboardController, animated: true, completion: nil)
    }
}


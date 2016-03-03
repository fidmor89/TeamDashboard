//
//  FirstViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/18/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    @IBOutlet weak var btnPickProject: UIButton!
    @IBOutlet weak var burnChartImageView: UIImageView!
    
    //Team Name and Features in Progress
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var IterationLabel: UILabel!
    @IBOutlet weak var RemainingWorkDaysLabel: UILabel!
    
    //Current Sprint Status
    @IBOutlet weak var NewPBIsCountLabel: UILabel!
    @IBOutlet weak var ApprovedPBIsCountLabel: UILabel!
    @IBOutlet weak var CommitedPBIsCountLabel: UILabel!
    @IBOutlet weak var DonePBIsLabel: UILabel!
    @IBOutlet weak var OpenImpedimentsCount: UILabel!
    
    //Quality Stats - Current Sprint
    @IBOutlet weak var ActiveDefectsCountLabel: UILabel!
    @IBOutlet weak var closedDefectsCountLabel: UILabel!
    @IBOutlet weak var SprintTestCasesCountLabel: UILabel!
    @IBOutlet weak var TotalTestCasesCreatedCountLabel: UILabel!
    @IBOutlet weak var TotalTestCasesAutomatedCountLabel: UILabel!
    
    //Today Section
    @IBOutlet weak var BuildStatusLabel: UILabel!
    @IBOutlet weak var BuildTestStatusLabel: UILabel!
    @IBOutlet weak var DeployStatusLabel: UILabel!
    @IBOutlet weak var CompilationTimeLabel: UILabel!
    @IBOutlet weak var CodeCoverageLabel: UILabel!
    @IBOutlet weak var NumLinesLabel: UILabel!
    
    private func listenChanges(){
        //Run in backgroud Thread
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            
            while !StateManager.SharedInstance.changed{
                sleep(1)                                            //Pause thread 1 second
            }
            
            StateManager.SharedInstance.changed = false
            
            //Run in Main Thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.drawDashboard()
            })
            
            self.listenChanges()                                    //Keep Listening for future changes
            
        })//end backgorud thread
        
    }
    
    private func drawDashboard(){
        let selectedTeam = StateManager.SharedInstance.team
        
        //Team Name and Features in progress
        self.teamNameLabel.text = selectedTeam.name         //Display team name.
        
        RestApiManager.sharedInstance.teamId = selectedTeam.id

        //Current Sprint Status
        RestApiManager.sharedInstance.getCurrentSprint { json in
            let count: Int = json["count"].int as Int!         //number of objects within json obj
            var jsonOBJ = json["value"]
            
            for index in 0...(count-1) {
                
                let name: String = jsonOBJ[index]["name"].string as String! ?? ""
                let path: String = jsonOBJ[index]["path"].string as String! ?? ""
                RestApiManager.sharedInstance.iterationPath = path
                let startDate: String = jsonOBJ[index]["attributes"]["startDate"].string as String! ?? ""
                let endDate: String = jsonOBJ[index]["attributes"]["finishDate"].string as String! ?? ""
                
                var formatedStartDate: String = ""
                var formatedEndDate: String = ""
                var leftWorkDays: String = "-> Sprint Finished"
                if startDate != "" && endDate != ""{
                    
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"                           //input format
                    let dateStart = dateFormatter.dateFromString(startDate)
                    let dateEnd = dateFormatter.dateFromString(endDate)
                    
                    dateFormatter.dateFormat = "MMMM d"                                             //output format
                    formatedStartDate = dateFormatter.stringFromDate(dateStart!)
                    formatedEndDate = dateFormatter.stringFromDate(dateEnd!)
                    
                    RestApiManager.sharedInstance.getTeamSettings(selectedTeam, onCompletion: { json in
                        var workingDays = json["workingDays"]
                        var intWorkingDays : [Int] = []
                        for index in 0...(workingDays.count - 1) {
                            switch (workingDays[index]) {
                            case "monday":
                                intWorkingDays.append(2)
                                break
                            case "tuesday":
                                intWorkingDays.append(3)
                                break
                            case "wednesday":
                                intWorkingDays.append(4)
                                break
                            case "thursday":
                                intWorkingDays.append(5)
                                break
                            case "friday":
                                intWorkingDays.append(6)
                                break
                            case "saturday":
                                intWorkingDays.append(7)
                                break
                            case "sunday":
                                intWorkingDays.append(1)
                                break
                            default:
                                break
                            }
                        }
                        let cal = NSCalendar.currentCalendar()
                        var comp : NSDateComponents
                        var daysRemaining : Int = 0
                        var today = NSDate()
                        while today.compare(dateEnd!) != NSComparisonResult.OrderedDescending {     // only if dateStart is earlier than dateEnd
                            comp = cal.components(NSCalendarUnit.Weekday, fromDate: today)
                            for i in 0...(intWorkingDays.count - 1) {
                                if comp.weekday == intWorkingDays[i] {
                                    daysRemaining++
                                    break
                                }
                            }
                            today = today.dateByAddingTimeInterval(60*60*24)
                        }
                        
                        if daysRemaining > 0 {
                            leftWorkDays = "-> \(daysRemaining) work days remaining"
                        }
                        else {
                            
                        }
                        dispatch_async(dispatch_get_main_queue(),{
                            self.RemainingWorkDaysLabel.text = "\(formatedStartDate) - \(formatedEndDate) \(leftWorkDays)"
                        })
                    })
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if formatedStartDate == ""{
                        self.IterationLabel.text = "\(name)"
                        self.RemainingWorkDaysLabel.text = ""
                    } else {
                        self.IterationLabel.text = "\(name)"
                    }
                })
            }
        }
        while(RestApiManager.sharedInstance.iterationPath == ""){}
        
        //Get Last build
        RestApiManager.sharedInstance.getLastBuild(selectedTeam, onCompletion: { json in
            let count: Int = json["count"].int as Int!
            var jsonOBJ = json["value"]
            var status: String = ""
            var compilationTime: String = ""
            if (count > 0) {
                status = jsonOBJ[0]["status"].string as String! ?? ""
                let startTime: String = jsonOBJ[0]["startTime"].string as String! ?? ""
                let finishTime: String = jsonOBJ[0]["finishTime"].string as String! ?? ""
                var dStartTime : NSDate
                var dFinishTime : NSDate
                let dateFormatter : NSDateFormatter = NSDateFormatter()
                let cal: NSCalendar = NSCalendar.currentCalendar()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.S'Z'"
                var components : NSDateComponents
                
                if startTime != "" && finishTime != "" {
                    dStartTime = dateFormatter.dateFromString(startTime)!
                    dFinishTime = dateFormatter.dateFromString(finishTime)!
                    components = cal.components(NSCalendarUnit.Second, fromDate: dStartTime, toDate: dFinishTime,
                        options: [])
                    compilationTime = String(components.second) + "." + String(components.nanosecond)
                }
                
                
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.BuildStatusLabel.text = status
                self.CompilationTimeLabel.text = compilationTime
            })
            
            
        })
        
        //Features
        setWorkItemsCount("[System.State] = 'New'",WorkItemType: "Product Backlog Item", controlObject: self.NewPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Approved'",WorkItemType: "Product Backlog Item", controlObject: self.ApprovedPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Committed'",WorkItemType: "Product Backlog Item", controlObject: self.CommitedPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Done'",WorkItemType: "Product Backlog Item", controlObject: self.DonePBIsLabel)
        setWorkItemsCount("[System.State] = 'Open'", WorkItemType: "Impediment", controlObject: self.OpenImpedimentsCount)
        
        //QA Stats
        setWorkItemsCount("[System.State] = 'New' or [System.State] = 'Approved' or [System.State] = 'Committed'", WorkItemType: "Bug", controlObject: self.ActiveDefectsCountLabel)
        setWorkItemsCount("[System.State] = 'Done'", WorkItemType: "Bug", controlObject: self.closedDefectsCountLabel)
        
        setWorkItemsCount("", WorkItemType: "Test Case", controlObject: self.SprintTestCasesCountLabel)
        
        setTestCasesCount(selectedTeam, Automated: false, WorkItemType: "Test Case", controlObject: self.TotalTestCasesCreatedCountLabel)
        setTestCasesCount(selectedTeam, Automated: true, WorkItemType: "Test Case", controlObject: self.TotalTestCasesAutomatedCountLabel)

        loadBurnChart()
    }
    
    func loadBurnChart(){
        if let imageURL = RestApiManager.sharedInstance.searchURLWithTerm(StateManager.SharedInstance.team){
            
            let request1: NSMutableURLRequest = NSMutableURLRequest(URL: imageURL)
            request1.setValue(RestApiManager.sharedInstance.buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            
            NSURLConnection.sendAsynchronousRequest(
                request1, queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        self.burnChartImageView.image = UIImage(data: data!)
                    }
            })
        }else{
            print("Invalid image URL")
        }
    }
    
    func setTestCasesCount(selectedTeam: Team, Automated: Bool, WorkItemType: String, controlObject:UILabel){
        RestApiManager.sharedInstance.countTestCases(selectedTeam, Automated: Automated, onCompletion:{json in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let workItems = json["workItems"].arrayValue
                controlObject.text = String(workItems.count)
            })
        })
    }
    
    func setWorkItemsCount(StateSelector: String, WorkItemType: String, controlObject:UILabel){
        RestApiManager.sharedInstance.countWorkItemType(StateSelector, WorkItemType: WorkItemType, onCompletion: {json in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let workItems = json["workItems"].arrayValue
                controlObject.text = String(workItems.count)
            })
        })
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listenChanges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showPickProjectModal(sender: AnyObject) {
    }
    
    
    @IBAction func logOutFunction(sender: AnyObject) {
        if (KeychainWrapper.hasValueForKey("credentials")){
            KeychainWrapper.removeObjectForKey("credentials")
        }
        
        //Get ViewController
        let loginController = self.storyboard!.instantiateViewControllerWithIdentifier("Login") as! LoginController
        
        //Dislpay the view controller
        self.presentViewController(loginController, animated: true, completion: nil)
    }
}


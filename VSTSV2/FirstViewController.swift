//
//  FirstViewController.swift
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
import SwiftCharts


class FirstViewController: UIViewController {
    
    @IBOutlet var parentView: UIView!
    @IBOutlet var viewSection: [UIView]!
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
    
    //Last Build Section
    @IBOutlet weak var LatestBuildDateLabel: UILabel!
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
    
    var buildsData = [(String, Double)]()
    
    private var chart: Chart?
    private var maxValue: Double = Double(1.0)
    
    private func drawBuildsGraph(){
        
        getBuildsData()
        
        let chartConfig = BarsChartConfig(
            valsAxisConfig: ChartAxisConfig(from: 0, to: ceil(maxValue) + (ceil(maxValue)/10), by: (ceil(maxValue)/10))
        )
        
        //tag = 1 -> UIView that should contain the builds graph
        if let latestBuildsViewSection: UIView = self.view.viewWithTag(1){
            
            //Remove previous views if any
            latestBuildsViewSection.subviews.forEach({  $0.removeFromSuperview()    })
            
            let marginSize = CGFloat(15)
            
            let chart = BarsChart(
                frame: CGRectMake(
                    marginSize,  //x position (relative to partent view)
                    marginSize,  //y position (relative to partent view)
                    latestBuildsViewSection.bounds.size.width - (2 * marginSize), //x size
                    latestBuildsViewSection.bounds.size.height - (2 * marginSize )), //y size
                chartConfig: chartConfig,
                xTitle: "Latest Builds",
                yTitle: "Seconds",
                bars: buildsData,
                color: UIColor(red: CGFloat(160/255.0), green: CGFloat(213/255.0), blue: CGFloat(227/255.0), alpha: CGFloat(1.0)),
                barWidth: (latestBuildsViewSection.bounds.size.width / (CGFloat)(buildsData.count)) - (3 * marginSize)
            )
            
            latestBuildsViewSection.addSubview(chart.view)
            self.chart = chart
        }else{
            print("View with tag 1 not found, check the storyboard")
        }
    }
    
    private func getBuildsData(){
        
        var waitingForBuildsData = true
        let selectedTeam = StateManager.SharedInstance.team
        buildsData = []     //Delete previous data.
        
        RestApiManager.sharedInstance.retrieveLatestBuilds(selectedTeam, top: 10) { json in
            
            let jsonOBJ = json["value"]
            for obj in jsonOBJ{
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.S'Z'"
                
                if let startTime = obj.1["startTime"].string{
                    
                    if let startDate = dateFormatter.dateFromString(startTime){
                        
                        if let finishTime = obj.1["finishTime"].string{
                            if let endDate = dateFormatter.dateFromString(finishTime){
                                
                                let dateFormatter : NSDateFormatter = NSDateFormatter()
                                let cal: NSCalendar = NSCalendar.currentCalendar()
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.S'Z'"
                                var components : NSDateComponents
                                
                                components = cal.components(
                                    NSCalendarUnit.Second,
                                    fromDate: startDate,
                                    toDate: endDate,
                                    options: []
                                )
                                
                                let strTime = (String(components.second) + "." + String(components.nanosecond))
                                if let n = NSNumberFormatter().numberFromString(strTime) {
                                    let buildTime = Double(n)
                                    
                                    if self.maxValue < buildTime{
                                        self.maxValue = buildTime
                                    }
                                    
                                    if let queueDate = dateFormatter.dateFromString(obj.1["queueTime"].string! as String){
                                        
                                        dateFormatter.dateFormat = "MMM dd"
                                        let queueDate = dateFormatter.stringFromDate(queueDate)
                                        self.buildsData.append((queueDate, buildTime))
                                    }else{
                                        self.buildsData.append(("Unknown", buildTime))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            waitingForBuildsData = false
        }
        
        while(waitingForBuildsData){
            sleep(1)
        }
    }
    
    private func drawDashboard(){
        var waitingForIterationPaht = true
        var abort = false
        let selectedTeam = StateManager.SharedInstance.team
        RestApiManager.sharedInstance.teamId = selectedTeam.id
        
        //Current Sprint Status
        RestApiManager.sharedInstance.getCurrentSprint { json in
            
            if let count: Int = json["count"].int as Int! {//If there is something in the JSON object
                var jsonOBJ = json["value"]
                
                for index in 0...(count-1) {
                    
                    let name: String = jsonOBJ[index]["name"].string as String! ?? ""
                    
                    let path: String = jsonOBJ[index]["path"].string as String! ?? ""
                    RestApiManager.sharedInstance.iterationPath = path
                    waitingForIterationPaht = false
                    
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
            }else{
                abort = true;
            }
        }
        
        //Waiting for iteration path to be set by background thread
        while(waitingForIterationPaht){
            
            if(abort){
                abort = false
                
                let alert = UIAlertController(
                    title: "Missing Sprint",
                    message: "The team you selected does not have any sprints assigned. contact your VSTS/TFS admin",
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return  //Stop wating and dont update the UI
            }
        }
        
        //Team Name and Features in progress
        self.teamNameLabel.text = selectedTeam.name         //Display team name.
        
        //Get Last build
        RestApiManager.sharedInstance.getLastBuild(selectedTeam, onCompletion: { json in
            let count: Int = json["count"].int as Int!
            var jsonOBJ = json["value"]
            var status: String = ""
            var compilationTime: String = ""
            var sLatestBuild : String = ""
            if (count > 0) {
                status = jsonOBJ[0]["status"].string as String! ?? "Unknown"
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
                    dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
                    sLatestBuild = dateFormatter.stringFromDate(dFinishTime)
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.BuildStatusLabel.text = status.trim()
                self.LatestBuildDateLabel.text = "Last Build: \(sLatestBuild)"
                self.drawBuildsGraph()
                
                //round time
                
                
//                let strTime = (String(components.second) + "." + String(components.nanosecond))
                if let n = NSNumberFormatter().numberFromString(compilationTime) {
                    let buildTime = Double(n)
                    self.CompilationTimeLabel.text = "\(ceil(buildTime)) Seconds"
                }else{
                    self.CompilationTimeLabel.text = "Unknown"
                }
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
                request1,
                queue: NSOperationQueue.mainQueue(),
                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    if error == nil {
                        if let image = UIImage(data: data!){
                            self.burnChartImageView.setImageWithAnimation(image)
                        }
                    }
                }
            )
        }else{
            self.burnChartImageView.setImageWithAnimation(UIImage(named: "sadFace")!)
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
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.drawBuildsGraph()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        
        let backgroud:UIColor = UIColor(patternImage: UIImage(named: "background")!)        //Create a color based on the backgroud image
        self.parentView.backgroundColor = backgroud                                         //set backgroud
        
        for view in self.viewSection{
            view.layer.cornerRadius = 10                                    //Round corners in sections
            view.layer.masksToBounds = true                                 //Keep child-views within the parent-view
            view.alpha = 0.75                                               //Semi transparent sections
            view.backgroundColor = UIColor.whiteColor()                     //White sections
        }
        listenChanges()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        drawBuildsGraph()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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


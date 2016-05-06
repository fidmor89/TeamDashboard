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
import MBProgressHUD
import Agrume

class FirstViewController: UIViewController {
    
    @IBOutlet var parentView: UIView!
    @IBOutlet var viewSection: [UIView]!
    @IBOutlet weak var btnPickProject: UIButton!
    @IBOutlet weak var burnChartImageView: UIImageView!
    var burnChartImage: UIImage? = nil
    
    //Team Name and Features in Progress
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
    @IBOutlet weak var BuildsTimeGraphTitile: UILabel!
    
    var step = 5.0

    private func listenChanges(){

        dispatch_async(GlobalUserInitiatedQueue, {
            
            while !StateManager.SharedInstance.changed{
                sleep(1)                                            //Pause thread 1 second
            }
            StateManager.SharedInstance.changed = false
            dispatch_async(GlobalMainQueue){        //Update UI
                self.drawDashboard()
            }
            self.listenChanges()                                    //Keep Listening for future changes
            
        })//end backgorud thread
        
    }
    
    var buildsData = [(String, Double)]()
    
    private var chart: Chart?
    private var maxValue: Double = Double(1.0)
    
    private func drawBuildsGraph(retrieveData: Bool = true){
        if StateManager.SharedInstance.team.id == "" { return } //not ready get display data.
        
        if retrieveData { getBuildsData() }
        
        //Display the data using the main thread
        dispatch_async(GlobalMainQueue) { () -> Void in
            
            if(UIDevice.currentDevice().modelName == "iPad Pro") { self.step = 10.0 }
            
            let chartConfig = BarsChartConfig(
                valsAxisConfig: ChartAxisConfig(from: 0, to: ceil(self.maxValue) + (ceil(self.maxValue)/self.self.step), by: (ceil(self.maxValue)/self.step))
            )
            
            //tag = 1 -> UIView that should contain the builds graph
            if let latestBuildsViewSection: UIView = self.view.viewWithTag(1){
                
                //Removes all ChartBaseView views
                latestBuildsViewSection.subviews.forEach({
                    if $0.isKindOfClass(ChartBaseView){
                        $0.removeFromSuperview()
                    }
                })
                
                let marginSize = CGFloat(15)
                
                let chart = BarsChart(
                    frame: CGRectMake(
                        marginSize,  //x position (relative to partent view)
                        2.5 * marginSize,  //y position (relative to partent view)
                        latestBuildsViewSection.bounds.size.width - (2 * marginSize), //x size
                        latestBuildsViewSection.bounds.size.height - (3.5 * marginSize )    //y size
                    ),
                    chartConfig: chartConfig,
                    xTitle: "Date",
                    yTitle: "Seconds",
                    bars: self.buildsData,
                    color: UIColor(red: CGFloat(160/255.0), green: CGFloat(213/255.0), blue: CGFloat(227/255.0), alpha: CGFloat(1.0)),
                    barWidth: (latestBuildsViewSection.bounds.size.width / (CGFloat)(self.buildsData.count)) - (3 * marginSize)
                )
                
                latestBuildsViewSection.addSubview(chart.view)
                
                self.parentView.bringSubviewToFront(self.BuildsTimeGraphTitile)
                self.chart = chart
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)         //Hide loading
                
            }else{
                print("View with tag 1 not found, check the storyboard")
            }
        }
    }
    
    private func getBuildsData(){
        
        var waitingForBuildsData = true
        let selectedTeam = StateManager.SharedInstance.team
        buildsData = []     //Delete previous data.
        
        var quantity = Int(step + 1)
        if(UIDevice.currentDevice().modelName == "iPad Pro")
        {
            quantity = 10
        }
        self.maxValue = 1
        RestApiManager.sharedInstance.retrieveLatestBuilds(selectedTeam, top: quantity) { json, result in
            if result.0 == 0{
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
            }else{
                self.showAlertMessage("Connection error", message: result.1, handler: nil)
            }
        }
        
        while(waitingForBuildsData){
            sleep(1)
        }
    }
    
    private func drawDashboard(){
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        
        var waitingForIterationPaht = true
        var abort = false
        let selectedTeam = StateManager.SharedInstance.team
        RestApiManager.sharedInstance.teamId = selectedTeam.id
        
        //Current Sprint Status
        RestApiManager.sharedInstance.getCurrentSprint { json, result in
            
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
                        
                        RestApiManager.sharedInstance.getTeamSettings(selectedTeam, onCompletion: { json, result in
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
                                        daysRemaining += 1
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
                            dispatch_async(GlobalMainQueue){
                                self.RemainingWorkDaysLabel.text = "\(formatedStartDate) - \(formatedEndDate) \(leftWorkDays)"
                            }
                        })
                    }
                    
                    dispatch_async(GlobalMainQueue){
                        if formatedStartDate == ""{
                            self.IterationLabel.text = "\(name)"
                            self.RemainingWorkDaysLabel.text = ""
                        } else {
                            self.IterationLabel.text = "\(name)"
                        }
                    }
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
                
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
                    self.btnPickProject.sendActionsForControlEvents(.TouchUpInside)     //Show pick project
                    StateManager.SharedInstance.team = StateManager.SharedInstance.previousTeam
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)         //Hide loading
                return  //Stop wating and dont update the UI
            }
        }
        
        //Team Name and Features in progress
        btnPickProject.setTitle(selectedTeam.name, forState: UIControlState.Normal)
        
        
        //Get Last build
        RestApiManager.sharedInstance.getLastBuild(selectedTeam, onCompletion: { json, result in
            let count: Int = json["count"].int as Int!
            var jsonOBJ = json["value"]
            var status: String = ""
            var build: Int = -1
            var compilationTime: String = ""
            var sLatestBuild : String = ""
            if (count > 0) {
                build = jsonOBJ[0]["id"].int as Int! ?? -1
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
                    dateFormatter.dateFormat = "MMM dd HH:mm:ss"
                    sLatestBuild = dateFormatter.stringFromDate(dFinishTime)
                    
                    //Code coverage metrics
                    RestApiManager.sharedInstance.getLastBuildCodeCoverage(selectedTeam, buildId: build, onCompletion: { json, result in
                        let count: Int = json["count"].int as Int!
                        var jsonOBJ = json["value"]
                        var blocksCovered : Int = 0
                        var linesCovered : Int = 0
                        if (count > 0) {
                            blocksCovered = jsonOBJ[0]["modules"]["statistics"]["blocksCovered"].int as Int! ?? 0
                            linesCovered = jsonOBJ[0]["modules"]["statistics"]["linesCovered"].int as Int! ?? 0
                        }
                        
                        dispatch_async(GlobalMainQueue){
                            self.CodeCoverageLabel.text = String(blocksCovered)
                            self.NumLinesLabel.text = String(linesCovered)
                        }
                    })
                }
            }
            
            dispatch_async(GlobalMainQueue){
                self.BuildStatusLabel.text = status.trim()
                self.LatestBuildDateLabel.text = "Last Build: \(sLatestBuild)"
                self.drawBuildsGraph()
                
                if let n = NSNumberFormatter().numberFromString(compilationTime) {
                    let buildTime = Double(n)
                    self.CompilationTimeLabel.text = "\(ceil(buildTime))"
                }else{
                    self.CompilationTimeLabel.text = "Unknown"
                }
                
                self.BuildTestStatusLabel.text = "Unknown"
                self.DeployStatusLabel.text = "Unknown"
            }
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
        dispatch_async(GlobalUserInteractiveQueue){
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
                                self.burnChartImage = image
                            }
                        }
                    }
                )
            }else{
                self.burnChartImageView.setImageWithAnimation(UIImage(named: "sadFace")!)
            }
        }
    }
    
    func setTestCasesCount(selectedTeam: Team, Automated: Bool, WorkItemType: String, controlObject:UILabel){
        RestApiManager.sharedInstance.countTestCases(selectedTeam, Automated: Automated, onCompletion:{ json, result in
            dispatch_async(GlobalMainQueue){
                let workItems = json["workItems"].arrayValue
                controlObject.text = String(workItems.count)
            }
        })
    }
    
    func setWorkItemsCount(StateSelector: String, WorkItemType: String, controlObject:UILabel){
        RestApiManager.sharedInstance.countWorkItemType(StateSelector, WorkItemType: WorkItemType, onCompletion: { json, result in
            let workItems = json["workItems"].arrayValue
            dispatch_async(GlobalMainQueue){
                controlObject.text = String(workItems.count)
            }
        })
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.drawBuildsGraph(false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
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
        
        // case of normal image
        let image1 = UIImage(named: "reload")!
        reloadButton.setImage(image1, forState: UIControlState.Normal)
        
        // case of when button is clicked
        let image2 = UIImage(named: "reloadHighlighted")!
        reloadButton.setImage(image2, forState: UIControlState.Highlighted)
        
        listenChanges()
        
        //Pick Project
        self.btnPickProject.sendActionsForControlEvents(.TouchUpInside)
        
        createTapGesture(#selector(FirstViewController.burnChartTap), UIControl: self.burnChartImageView)
        if let latestBuildsViewSection: UIView = self.view.viewWithTag(1){
            createTapGesture(#selector(FirstViewController.latestBuildsTap), UIControl: latestBuildsViewSection)
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        dispatch_async(GlobalUserInitiatedQueue) {
            self.drawBuildsGraph(false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func reloadButtonTouchUpInside(sender: AnyObject) {
        if StateManager.SharedInstance.team.id != "" {
            print("Reloading...")
            self.drawDashboard()
        }
    }
    
    @IBOutlet weak var reloadButton: UIButton!
    
    @IBAction func logOutFunction(sender: AnyObject) {
        if (KeychainWrapper.hasValueForKey("credentials")){
            KeychainWrapper.removeObjectForKey("credentials")
        }
        
        StateManager.SharedInstance.team = Team()
        
        //Get ViewController
        let loginController = self.storyboard!.instantiateViewControllerWithIdentifier("Login") as! LoginController
        
        //Dislpay the view controller
        self.presentViewController(loginController, animated: true, completion: nil)
    }
    
    func latestBuildsTap(){
        print("latest build tapped")
    }
    
    func burnChartTap(){
        if let image = burnChartImage {
            
            //capture current background
            let window: UIWindow! = UIApplication.sharedApplication().keyWindow
            let windowImage = window.capture()
            
            //Initialize agrume
            let agrume = Agrume(image: image)
            agrume.showFrom(self, windowImage: windowImage)
        }
    }
    
}
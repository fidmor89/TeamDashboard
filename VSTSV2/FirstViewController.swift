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
    @IBOutlet weak var BurnChartWebView: UIWebView!
    
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
        self.teamNameLabel.text = selectedTeam.name         //Display tema name.
        
        RestApiManager.sharedInstance.teamId = selectedTeam.id
        
        //Current Sprint Status
        RestApiManager.sharedInstance.getCurrentSprint { json in
            var count: Int = json["count"].int as Int!         //number of objects within json obj
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
                    
                    let cal = NSCalendar.currentCalendar()
                    let unit:NSCalendarUnit = .CalendarUnitDay
                    
                    let components = cal.components(unit, fromDate: NSDate(), toDate: dateEnd!, options: nil)
                    
                    if components.day > 0{
                        leftWorkDays = "-> \(components.day) work days remaining"
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if formatedStartDate == ""{
                        self.IterationLabel.text = "\(name)"
                        self.RemainingWorkDaysLabel.text = ""
                    }else{
                        self.IterationLabel.text = "\(name)"
                        self.RemainingWorkDaysLabel.text = "\(formatedStartDate) - \(formatedEndDate) \(leftWorkDays)"
                    }
                })
            }
        }
        
        
        //Burndown Chart
        //        RestApiManager.sharedInstance.getBurnChart(selectedTeam){ (dataImage) in
        //
        //            dispatch_async(dispatch_get_main_queue(), {
        ////                self.burnChartImageView.image = UIImage(data: dataImage)
        ////                self.BurnChartWebView.loadData(dataImage, MIMEType: "image/jpeg", textEncodingName: nil, baseURL: nil)
        //
        ////                if let checkedUrl = NSURL(string: dataImage){
        ////                    self.burnChartImageView.contentMode = .ScaleAspectFit
        ////                    self.downloadImage(checkedUrl)
        ////                }
        //
        //            })
        //        }
        
        
        //QA Stats
        
        let statesForPBIs = ["New","Approved","Committed","Done"]
        
        
        setWorkItemsCount("[System.State] = 'New'",WorkItemType: "Product Backlog Item", controlObject: self.NewPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Approved'",WorkItemType: "Product Backlog Item", controlObject: self.ApprovedPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Committed'",WorkItemType: "Product Backlog Item", controlObject: self.CommitedPBIsCountLabel)
        setWorkItemsCount("[System.State] = 'Done'",WorkItemType: "Product Backlog Item", controlObject: self.DonePBIsLabel)
        setWorkItemsCount("[System.State] = 'Open'", WorkItemType: "Impediment", controlObject: self.OpenImpedimentsCount)
        
        setWorkItemsCount("[System.State] = 'New' or [System.State] = 'Approved' or [System.State] = 'Committed'", WorkItemType: "Bug", controlObject: self.ActiveDefectsCountLabel)
        setWorkItemsCount("[System.State] = 'Done'", WorkItemType: "Bug", controlObject: self.closedDefectsCountLabel)
        
        setTestCasesCount("", Automated: false, WorkItemType: "Test Case", controlObject: self.TotalTestCasesCreatedCountLabel)
//        setTestCasesCount("", WorkItemType: "Test Case", controlObject: self.TotalTestCasesCreatedCountLabel)

        
        
        
        
        //Latest Build Times
        //Test, Build, Deploy and code metrics
        
        
        
    }
    
    func setTestCasesCount(StateSelector: String, Automated: Bool, WorkItemType: String, controlObject:UILabel){
        RestApiManager.sharedInstance.countTestCases("Url2015Project\\\\iOSTeamExplorer", Automated: Automated, onCompletion:{json in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let workItems = json["workItems"].arrayValue
                println(workItems)
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
    func downloadImage(url: NSURL){
        print("Download Started")
        print("lastPathComponent: " + (url.lastPathComponent ?? ""))
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                //                guard let data = data where error == nil else { return }                  //only from Swift2
                
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                self.burnChartImageView.image = UIImage(data: data!)
                self.BurnChartWebView.loadData(data!, MIMEType: "image/jpeg", textEncodingName: nil, baseURL: nil)
            }
        }
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
}


//
//  PickProjectViewController.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/23/16.
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

class PickProjectViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var projects : [Team] = []
    var filterProjects : [Team] = []
    var displayingLoadingNotification = false
    var defaultWidth: CGFloat = 0.0
    func getProjects(){
        
        dispatch_async(GlobalUserInteractiveQueue){
//            RestApiManager.sharedInstance.getCollections { json, result in
//                if (result.0 == 0){
//                    let count: Int = json["count"].int as Int!         //number of objects within json obj
//                    var jsonOBJCollections = json["value"]                         //get json with projects
//                    for index in 0...(count-1) {                        //for each obj in jsonOBJ
            
                        //                        let collectionTemp = jsonOBJCollections[index]["name"].string as String! ?? ""
                        let collectionTemp = "DefaultCollection"
                        RestApiManager.sharedInstance.collection = collectionTemp
                        
                        RestApiManager.sharedInstance.getProjects { json, result in
                            if(result.0 == 0){
                                let count: Int = json["count"].int as Int!         //number of objects within json object
                                var jsonOBJProjects = json["value"]                        //get json with projects
                                
                                for index in 0...(count-1) {                        //for each obj in jsonOBJ
                                    
                                    RestApiManager.sharedInstance.projectId = jsonOBJProjects[index]["id"].string as String! ?? ""
                                    let projectTemp = jsonOBJProjects[index]["name"].string as String! ?? ""
                                    
                                    RestApiManager.sharedInstance.getTeamProjects { json, result in
                                        if result.0 == 0{
                                            let count: Int = json["count"].int as Int!         //number of objects within json obj
                                            var jsonOBJ = json["value"]                         //get json with projects
                                            
                                            for index in 0...(count-1) {                        //for each obj in jsonOBJ
                                                
                                                var project : Team = Team()
                                                
                                                project.id = jsonOBJ[index]["id"].string as String! ?? ""
                                                project.name = jsonOBJ[index]["name"].string as String! ?? ""
                                                project.url = jsonOBJ[index]["url"].string as String! ?? ""
                                                project.description = jsonOBJ[index]["description"].string as String! ?? ""
                                                project.state = jsonOBJ[index]["state"].string as String! ?? ""
                                                project.revision = jsonOBJ[index]["revision"].string as String! ?? ""
                                                project.Collection = collectionTemp
                                                project.Project = projectTemp
                                                
                                                //                                print("Collection: \(project.Collection)")
                                                //                                print("Project: \(project.Project)")
                                                //                                print("Team: \(project.name)")
                                                //                                print("")
                                                
                                                self.projects.append(project)
                                                
                                                dispatch_async(GlobalMainQueue){
                                                    self.tableView?.reloadData()
                                                    
                                                    var frame = self.tableView.frame;
                                                    let heightValue = min(CGFloat(70 * self.projects.count), UIScreen.mainScreen().bounds.height)
                                                    frame.size.height = CGFloat(heightValue)
                                                    self.tableView.frame = frame                                    //table view size
                                                    self.preferredContentSize.height = CGFloat(heightValue)         //Controller size
                                                }
                                            }
                                        }else{
                                            self.showAlertMessage("Connection error", message: result.1, handler: nil)
                                        }
                                        
                                    }
                                }
                            }else{
                                self.showAlertMessage("Connection error", message: result.1, handler: nil)
                            }
                        }
                        
//                    }
//                }else{
//                    self.showAlertMessage("Connection error", message: result.1, handler: nil)
//                }
//            }
        }
        
    }
    
    // Overridable methods
    override func viewDidLoad() {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        //Initial size
        self.preferredContentSize.height = CGFloat(100)
        self.defaultWidth = self.preferredContentSize.width
        self.preferredContentSize.width = CGFloat(100)
        getProjects()
        
        self.tableView?.alwaysBounceVertical = false    //If projects fit in the window there should be no scroll.
        
        self.tableView.separatorColor = UIColor.clearColor()
        
        
        let backgroundImage = UIImage(named: "background")
        let imageView = UIImageView(image: backgroundImage)
        
        if UIDevice().isBlurSupported() &&  !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = imageView.bounds
            imageView.addSubview(blurView)
            tableView.backgroundView = imageView
        }else{
            tableView.backgroundView = UIImageView(image: UIImage(named: "preBlurredBackground"))
        }
        
        
        let backColor = UIColor(patternImage: UIImage(named: "background")!)
        
        if let _ = self.searchDisplayController{
            self.searchDisplayController!.searchResultsTableView.backgroundColor = backColor
            self.searchDisplayController!.searchResultsTableView.separatorColor = UIColor.clearColor()
            self.searchDisplayController!.searchResultsTableView.rowHeight = self.tableView!.rowHeight
        }
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
    }
    
    // Selected a row
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        StateManager.SharedInstance.previousTeam = StateManager.SharedInstance.team
        
        StateManager.SharedInstance.team = projects[indexPath.row]
        if let search = self.searchDisplayController{
            if tableView == search.searchResultsTableView {
                StateManager.SharedInstance.team = filterProjects[indexPath.row]
            }
        }
        
        StateManager.SharedInstance.changed = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Return the number of rows in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let search = self.searchDisplayController{
            if tableView == search.searchResultsTableView {
                return self.filterProjects.count
            }
        }
        
        return self.projects.count
        
    }
    
    // Fill table with information about teams
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)         //Hide loading
        
        var cell = self.tableView!.dequeueReusableCellWithIdentifier("ProjectCell") as? WorkItemCell
        if cell == nil {
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "ProjectCell")
        }
        
        var arrayOfProjects: Array<Team>? = self.projects
        
        self.preferredContentSize.width = self.defaultWidth
        if let search = self.searchDisplayController{
            if tableView == search.searchResultsTableView {
                arrayOfProjects = self.filterProjects
            }
        }
        
        if arrayOfProjects != nil && arrayOfProjects!.count >= indexPath.row {
            let project = arrayOfProjects![indexPath.row]
            cell!.titleText.text = project.name
            cell!.detailText.text = project.Collection + "/" + project.Project
        }
        
        cell?.textLabel?.backgroundColor = UIColor.clearColor()
        
        cell?.contentView.backgroundColor = UIColor.whiteColor()
        cell?.contentView.layer.cornerRadius = 10
        cell?.contentView.layer.masksToBounds = true
        cell?.contentView.alpha = 0.75
        
        cell?.backgroundColor = UIColor.clearColor()
        
        return cell!
    }
    
    func filterContentForSearchText(searchText: String, scope: Int) {
        if self.projects.count == 0 {
            self.filterProjects.removeAll(keepCapacity: false)
            return
        }
        
        self.filterProjects = self.projects.filter({( aProject: Team) -> Bool in
            
            var fieldToSearch : String?
            switch (scope) {
            case 0:
                fieldToSearch = aProject.name
                break
            case 1:
                fieldToSearch = aProject.Project
                break
            case 2:
                fieldToSearch = aProject.Collection
                break
            default:
                fieldToSearch = nil
                break
            }
            if fieldToSearch == nil {
                self.filterProjects.removeAll(keepCapacity: false)
                return false
            }
            
            return fieldToSearch!.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
        })
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didLoadSearchResultsTableView tableView: UITableView) {
        //tableView.rowHeight = 120
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        let selectedIndex = controller.searchBar.selectedScopeButtonIndex
        self.filterContentForSearchText(searchString!, scope: selectedIndex)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        let searchString = controller.searchBar.text
        self.filterContentForSearchText(searchString!, scope: searchOption)
        return true
    }
    
    
    
    
    
}
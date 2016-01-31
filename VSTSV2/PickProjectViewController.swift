//
//  PickProjectViewController.swift
//  VSTSV2
//
//  Created by Giorgio Balconi on 1/23/16.
//  Updated by Fidel Esteban Morales Cifuentes on 1/28/16
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit
import MBProgressHUD

class PickProjectViewController: UITableViewController {
    
    var projects : [TeamProject] = []
    var displayingLoadingNotification = false
    
    func getProjects(){
        
        
        var defaultCollections:[String] = []
        
        RestApiManager.sharedInstance.getCollections { json in
            var count: Int = json["count"].int as Int!         //number of objects within json obj
            var jsonOBJ = json["value"]                         //get json with projects
            
            for index in 0...(count-1) {                        //for each obj in jsonOBJ
                
                RestApiManager.sharedInstance.collection = jsonOBJ[index]["name"].string as String! ?? ""
                
                RestApiManager.sharedInstance.getProjects { json in
                    var count: Int = json["count"].int as Int!         //number of objects within json object
                    var jsonOBJ = json["value"]                        //get json with projects
                    
                    for index in 0...(count-1) {                        //for each obj in jsonOBJ
                        
                        
                        RestApiManager.sharedInstance.projectId = jsonOBJ[index]["id"].string as String! ?? ""
                        
                        RestApiManager.sharedInstance.getTeamProjects { json in
                            var count: Int = json["count"].int as Int!         //number of objects within json obj
                            var jsonOBJ = json["value"]                         //get json with projects
                            
                            for index in 0...(count-1) {                        //for each obj in jsonOBJ
                                
                                var project : TeamProject = TeamProject()
                                
                                project.id = jsonOBJ[index]["id"].string as String! ?? ""
                                project.name = jsonOBJ[index]["name"].string as String! ?? ""
                                project.url = jsonOBJ[index]["url"].string as String! ?? ""
                                project.description = jsonOBJ[index]["description"].string as String! ?? ""
                                project.state = jsonOBJ[index]["state"].string as String! ?? ""
                                project.revision = jsonOBJ[index]["revision"].string as String! ?? ""
                                
                                self.projects.append(project)
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.tableView?.reloadData()})              //reload UI data.
                            }
                        }
                    }
                    
                    
                }
                
            }
        }
        
    }
    
    // Overridable methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.alwaysBounceVertical = false            //If projects fit in the window there should be no scroll.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getProjects()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
    }
    
    // Selected a row
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        StateManager.SharedInstance.team = projects[indexPath.row]
        StateManager.SharedInstance.changed = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Return the number of rows in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count;
    }
    
    // Fill table with information about teams
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var index = indexPath.row
        
        var cell = tableView.dequeueReusableCellWithIdentifier("ProjectCell") as? WorkItemCell
        if cell == nil{
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "ProjectCell")
        }
        
        var project = projects[index]
        cell!.titleText.text = project.name
        cell!.detailText.text = ""
        return cell!
    }
}
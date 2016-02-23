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

class PickProjectViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var projects : [Team] = []
    var filterProjects : [Team] = []
    var displayingLoadingNotification = false
    
    func getProjects(){
        
        
        var defaultCollections:[String] = []
        
        RestApiManager.sharedInstance.getCollections { json in
            var count: Int = json["count"].int as Int!         //number of objects within json obj
            var jsonOBJCollections = json["value"]                         //get json with projects
            
            for index in 0...(count-1) {                        //for each obj in jsonOBJ
                
                let collectionTemp = jsonOBJCollections[index]["name"].string as String! ?? ""
                RestApiManager.sharedInstance.collection = collectionTemp
                
                RestApiManager.sharedInstance.getProjects { json in
                    var count: Int = json["count"].int as Int!         //number of objects within json object
                    var jsonOBJProjects = json["value"]                        //get json with projects
                    
                    for index in 0...(count-1) {                        //for each obj in jsonOBJ
                        
                        RestApiManager.sharedInstance.projectId = jsonOBJProjects[index]["id"].string as String! ?? ""
                        let projectTemp = jsonOBJProjects[index]["name"].string as String! ?? ""
                        
                        RestApiManager.sharedInstance.getTeamProjects { json in
                            
                            var count: Int = json["count"].int as Int!         //number of objects within json obj
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

                                println("Collection: \(project.Collection)")
                                println("Project: \(project.Project)")
                                println("Team: \(project.name)")
                                println()
                                
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
        self.searchDisplayController!.searchResultsTableView!.rowHeight = self.tableView!.rowHeight
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
        if tableView == self.searchDisplayController!.searchResultsTableView {
            StateManager.SharedInstance.team = filterProjects[indexPath.row]
        } else {
            StateManager.SharedInstance.team = projects[indexPath.row]
        }
        StateManager.SharedInstance.changed = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Return the number of rows in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filterProjects.count
        } else {
            return self.projects.count
        }
    }
    
    // Fill table with information about teams
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.tableView!.dequeueReusableCellWithIdentifier("ProjectCell") as? WorkItemCell
        if cell == nil {
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "ProjectCell")
        }
        
        var arrayOfProjects: Array<Team>?
        if tableView == self.searchDisplayController!.searchResultsTableView {
            arrayOfProjects = self.filterProjects
        } else {
            arrayOfProjects = self.projects
        }
        
        if arrayOfProjects != nil && arrayOfProjects!.count >= indexPath.row {
            let project = arrayOfProjects![indexPath.row]
            cell!.titleText.text = project.name
            cell!.detailText.text = project.Collection + "/" + project.Project
        }
        
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
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        let selectedIndex = controller.searchBar.selectedScopeButtonIndex
        self.filterContentForSearchText(searchString, scope: selectedIndex)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        let searchString = controller.searchBar.text
        self.filterContentForSearchText(searchString, scope: searchOption)
        return true
    }
    
}
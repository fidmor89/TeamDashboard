//
//  PickProjectViewController.swift
//  VSTSV2
//
//  Created by Giorgio Balconi on 1/23/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit

class PickProjectViewController: UITableViewController {
    
    var projects : [TeamProject] = []
    
    // Dummy data
    func getProjects(){
        var project : TeamProject
        
        for i in 1...10 {
            project = TeamProject()
            project.id = i
            project.name = "Project " + String(i)
            project.description = "Project number " + String(i)
            project.url = "https://www.google.com"
            
            projects.append(project)
        }
    }
    
    // Overridable methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Return the number of rows in the table
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count;
    }
    
    // Fill table with information about projects
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("ProjectCell") as? WorkItemCell
        if cell == nil{
            cell = WorkItemCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "ProjectCell")
        }
        var index = indexPath.row
        var project = projects[index]
        cell!.titleText.text = project.name
        cell!.detailText.text = project.description
        return cell!
    }
}
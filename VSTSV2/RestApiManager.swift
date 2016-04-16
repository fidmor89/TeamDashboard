//
//  RestApiManager.swift
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

import Foundation
import SwiftyJSON
import SwiftHTTP

typealias ServiceResponse = (JSON, NSError?) -> Void

class RestApiManager: NSObject {
    
    static let sharedInstance = RestApiManager()            //To use manager class as a singleton.
    internal var baseURL: String = ""
    internal var usr: String = ""
    internal var pw: String = ""
    internal var collection: String? = nil
    internal var projectId: String? = nil
    internal var teamId: String = ""
    internal var iterationPath: String = ""
    internal var lastResponseCode = ""
    
    func initialize(){
        self.collection = nil
        self.projectId = nil
        self.teamId = ""
    }
    
    func validateAuthorization(onCompletionAuth: (Bool, String) -> Void){
        let route = baseURL + "/_apis/projectcollections"
        
        retrieveHTTPGetRequest(route, onCompletion:  {(response: Response) in
            
            if let err = response.error {
                self.setLastResponseCode(response)
                onCompletionAuth(false, err.localizedDescription)
                return
            }else if let status = response.statusCode {
                
                switch status{
                case 200:
                    onCompletionAuth(true, "Auth Ok")
                    break;
                default:
                    onCompletionAuth(false, "Login Failed, try again.")
                    break;
                }
            }else{
                onCompletionAuth(false, "Login Failed, try again.")
            }
        })
    }
    
    func getBurnChart(team: Team, onCompletion: (data: NSData) -> Void ){
        
        let route = baseURL + "/\(team.Collection)/\(team.Project)/\(team.name)/_api/_teamChart/Burndown?chartOptions=%7B%22Width%22%3A936%2C%22Height%22%3A503%2C%22ShowDetails%22%3Atrue%2C%22Title%22%3A%22%22%7D&counter=2&iterationPath=\(iterationPath)&__v=5"
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            onCompletion(data: data)    //Pass back NSData object with the image contents
        })
    }
    
    func getComulativeFlow(team:Team, Category:String) -> NSURL? {
        
        if let components = NSURLComponents(string: baseURL) {
            
            components.path =  "/\(team.Collection)/\(team.Project)/\(team.name)/_api/_teamChart/CumulativeFlow"
            
            components.queryItems = [
                NSURLQueryItem(name: "chartOptions", value:"{\"Width\":936,\"Height\":503,\"ShowDetails\":true,\"Title\":\"\"}"),
                NSURLQueryItem(name: "counter", value: "2"),
                NSURLQueryItem(name: "hubCategoryRefName", value:Category),
                NSURLQueryItem(name: "__v", value: "5")]
            return components.URL
        }
        return nil
    }
    
    func getVelocityURL(team:Team) -> NSURL? {
        if let components = NSURLComponents(string: baseURL) {
            
            components.path =  "/\(team.Collection)/\(team.Project)/\(team.name)/_api/_teamChart/Velocity"
            
            components.queryItems = [
                NSURLQueryItem(name: "chartOptions", value:"{\"Width\":936,\"Height\":503,\"ShowDetails\":true,\"Title\":\"\"}"),
                NSURLQueryItem(name: "counter", value: "2"),
                NSURLQueryItem(name: "iterationsNumber", value:"6"),
                NSURLQueryItem(name: "__v", value: "5")]
            return components.URL
        }
        return nil
    }
    
    func searchURLWithTerm(team:Team) -> NSURL? {
        
        if let components = NSURLComponents(string: baseURL) {
            
            components.path = "/\(team.Collection)/\(team.Project)/\(team.name)/_api/_teamChart/Burndown"
            
            components.queryItems = [
                NSURLQueryItem(name: "chartOptions", value:"{\"Width\":936,\"Height\":503,\"ShowDetails\":true,\"Title\":\"\"}"),
                NSURLQueryItem(name: "counter", value: "2"),
                NSURLQueryItem(name: "iterationPath", value:  self.iterationPath),
                NSURLQueryItem(name: "__v", value: "5")
            ]
            
            return components.URL
        }
        return nil
    }
    
    func getTeamSettings(team:Team, onCompletion: (JSON) -> Void) {
        let route = baseURL + "/\(team.Collection)/\(team.Project)/\(team.name)/_apis/work/teamsettings?api-version=2.0"
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getTeams(onCompletion: (JSON) -> Void) {
        
        let route = baseURL + "/\(collection!)/_apis/projects"       //API request route
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getTeamProjects(onCompletion: (JSON) -> Void) {
        let route = baseURL + "/\(collection!)/_apis/projects/\(projectId!)/teams"       //API request route
        
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getCollections(onCompletion: (JSON) -> Void) {
        
        let route = baseURL + "/_apis/projectcollections"       //API request route
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getProjects(onCompletion: (JSON) -> Void) {
        
        let route = baseURL + "/\(collection!)/_apis/projects"       //API request route
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getIterationsByTeamAndProject(onCompletion: (JSON) -> Void){
        let route = baseURL + "/\(collection!)/\(projectId!)/\(teamId)/_apis/work/teamsettings/iterations"
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getCurrentSprint(onCompletion: (JSON) -> Void){
        let route = baseURL + "/\(collection!)/\(projectId!)/\(teamId)/_apis/work/teamsettings/iterations?$timeframe=current"
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func retrieveLatestBuilds(team: Team, top: Int!, onCompletion: (JSON) -> Void) {
        
        
        let route = baseURL + "/\(team.Collection)/\(team.Project)/_apis/build/builds?api-version=2.0&$top=\(top!)"
        
        makeHTTPGetRequest(route, onCompletion: {(data: NSData) in
            let json:JSON = JSON(data: data, options: NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getLastBuild(team: Team, onCompletion: (JSON) -> Void) {
        let route = baseURL + "/\(team.Collection)/\(team.Project)/_apis/build/builds?api-version=2.0&$top=1"
        makeHTTPGetRequest(route, onCompletion: {(data: NSData) in
            let json:JSON = JSON(data: data, options: NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getLastBuildCodeCoverage(team: Team, buildId: Int, onCompletion: (JSON) -> Void) {
        let route = baseURL + "/\(team.Collection)/\(team.Project)/_apis/test/codeCoverage?buildId=\(buildId)&flags=7&api-version=2.0-preview"
        makeHTTPGetRequest(route, apiVersion: "2.0-preview", onCompletion: {(data: NSData) in
            let json: JSON = JSON(data: data, options: NSJSONReadingOptions.MutableContainers, error: nil)
            onCompletion(json)
        })
    }
    
    func getTaks(onCompletion: (JSON) -> Void){
        
        let newIteration = self.iterationPath.stringByReplacingOccurrencesOfString("\\", withString: "\\\\", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Task'  AND [System.IterationPath] = '\(newIteration)'\"}"
        
        queryServer(route, query: query, onCompletion: {data in
            onCompletion(data)                  //Pass up data
        })
        
    }
    
    private func runWIQL(Query: String, onCompletion: (JSON) -> Void){
        
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        queryServer(route, query: Query, onCompletion: { jsonData in
            onCompletion(jsonData)                      //Passing back the json object
        })
        
    }
    
    func countWorkItemType(var StateSelector: String, WorkItemType: String, onCompletion: (JSON) -> Void){
        
        if StateSelector != ""{
            StateSelector = "AND (\(StateSelector))"
        }
        
        let newIteration = self.iterationPath.stringByReplacingOccurrencesOfString("\\", withString: "\\\\", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        
        let query = "{\"query\": \"SELECT System.Id FROM WorkItems WHERE [System.WorkItemType] = '\(WorkItemType)'  AND [System.IterationPath] = '\(newIteration)' \(StateSelector)\"}"
        
        runWIQL(query, onCompletion: { jsonData in
            onCompletion(jsonData)
        })
    }
    
    func countTestCases(selectedTeam: Team, Automated: Bool, onCompletion: (JSON) -> Void){
        
        var Selector: String = "AND [System.AreaPath] under ' \(selectedTeam.Project)\\\\\(selectedTeam.name)'"     //area path is: Project\\Team
        if Automated{
            Selector += " AND [Microsoft.VSTS.TCM.AutomationStatus] = 'Automated'"
        }
        
        let query = "{\"query\": \"SELECT System.Id FROM WorkItems WHERE [System.WorkItemType] = 'Test Case' \(Selector)\"}"
        
        runWIQL(query, onCompletion: { jsonData in
            onCompletion(jsonData)
        })
    }
    
    func getActiveFeatures(selectedTeam: Team, onCompletion: (JSON) -> Void){
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems  WHERE [System.WorkItemType] = 'Feature' AND [System.AreaPath] = '\(selectedTeam.Project)\\\\\(selectedTeam.name)' AND [System.State]='In Progress'\"}"
        
        runWIQL(query, onCompletion: { jsonData in
            onCompletion(jsonData)
        })
        
    }
    
    func getFeature(url: String, onCompletion: (JSON) -> Void){
        makeHTTPGetRequest(url, onCompletion: {(data: NSData) in
            let json:JSON = JSON(data: data, options: NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)
        })
    }
    
    func getEpics(onCompletion: (JSON) -> Void){
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems  WHERE [System.WorkItemType] = 'Epic' AND [System.AreaPath] = '\(projectId!)\\\\\(teamId)'\"}"
        
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        
        queryServer(route, query: query, onCompletion: {data in
            onCompletion(data)                  //Pass up data
        })
    }
    
    func getFeatures(onCompletion: (JSON) -> Void){
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems  WHERE [System.WorkItemType] = 'Feature' AND [System.AreaPath] = '\(projectId!)\\\\\(teamId)'\"}"
        
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        
        queryServer(route, query: query, onCompletion: {data in
            onCompletion(data)                  //Pass up data
        })
    }
    
    func getPBI(onCompletion: (JSON) -> Void){
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems  WHERE [System.WorkItemType] = 'Product Backlog Item' AND [System.AreaPath] = '\(projectId!)\\\\\(teamId)'\"}"
        
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        
        queryServer(route, query: query, onCompletion: {data in
            onCompletion(data)                  //Pass up data
        })
    }
    
    func queryServer(route: String, query: String, onCompletion: (JSON) -> Void){
        makeHTTPPostRequest(route, bodyContent: query, onCompletion: {(data: NSData) in
            //parse NSData to JSON
            let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
            onCompletion(json)            //return results from request
        })
    }
    
    func connectToWebAPI(){
        
        //setting up the base64-encoded credentials
        let loginString = NSString(format: "%@:%@", usr, pw)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = "Basic " + loginData.base64EncodedStringWithOptions([])
        
        //creating the request
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        let url = NSURL(string: route)
        let request = NSMutableURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        request.setValue(base64LoginString, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Product Backlog Item' AND [System.AreaPath] = 'Url2015Project\\\\iOSTeamExplorer' AND [System.IterationPath] = 'Url2015Project\\\\iOS_Team_Explorer_Collection\\\\SP5 - Epics, Features, PBI, Sprints and Work item views'\"}\"}"
        
        request.HTTPBody = query.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if (error != nil) { print(error) }
        })
        
        
        //fire off the request
        task.resume()
    }
    
    func makeHTTPPostRequest(path: String, bodyContent: String, onCompletion: (data: NSData) -> Void ){
        
        //create the request
        if let url = NSURL(string: path){
            
            let request = NSMutableURLRequest(URL: url)
            
            let session = NSURLSession.sharedSession()
            request.setValue(buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            request.HTTPMethod = "POST"
            request.HTTPBody = bodyContent.dataUsingEncoding(NSUTF8StringEncoding)
            
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                
                if let _ = error{
                    print("Post Request Error: \(error)")
                }
                
                if let _ = data{
                    onCompletion(data: data!)   //return data from POST request.
                }
            })
            
            task.resume()   //fire off the request
        }else{
            print("invalid url \(path)")
        }
    }
    
    func makeHTTPGetRequest(path: String, apiVersion: String = "2.0", onCompletion: (data: NSData) -> Void ){
        
        if let escapedAddress = path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()){
            do {
                let opt = try HTTP.GET(escapedAddress, parameters: [apiVersion], headers: ["Authorization": buildBase64EncodedCredentials()])
                opt.start { response in
                    if let err = response.error {
                        print("Get Request error: \(err.localizedDescription)")
                        self.setLastResponseCode(response)
                    }
                    
                    if let data = response.data as NSData? {
                        self.setLastResponseCode(response)
                        onCompletion(data: data)    //return data from GET request.
                    }
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }else {
            print("invalid url \(path)")
        }
        
    }
    
    func retrieveHTTPGetRequest(path: String, apiVersion: String = "2.0", onCompletion: (request: Response) -> Void ){
        
        if let escapedAddress = path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()){
            do {
                let opt = try HTTP.GET(escapedAddress, parameters: [apiVersion], headers: ["Authorization": buildBase64EncodedCredentials()])
                opt.start { response in
                    self.setLastResponseCode(response)
                    onCompletion(request: response)    //return the entire response
                    
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }else{
            print("invalid url \(path)")
        }
        
    }
    
    
    func setLastResponseCode(response: Response){
        if(response.statusCode != nil){
            self.lastResponseCode = String(response.statusCode!)
        }else{
            self.lastResponseCode = "400"
        }
    }
    
    func buildBase64EncodedCredentials() -> String{
        //setting up the base64-encoded credentials
        let loginString = NSString(format: "%@:%@", usr, pw)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        
        return "Basic " + base64LoginString
    }
}
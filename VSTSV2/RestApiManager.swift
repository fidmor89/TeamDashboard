//
//  RestApiManager.swift
//  TFS
//
//  Created by Fidel Esteban Morales Cifuentes on 1/18/16.
//  Copyright (c) 2015 Fidel Esteban Morales Cifuentes. All rights reserved.
//

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
    
    func validateAuthorization(onCompletionAuth: (Bool) -> Void){
        let route = baseURL + "/_apis/projectcollections"
        
        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
            
            switch self.lastResponseCode{
            case "200":
                onCompletionAuth(true)
                break;
            default:
                onCompletionAuth(false)
                break;
            }
        })
    }
    
    func getBurnChart(team: TeamProject, onCompletion: (data: NSData) -> Void ){
        
        let route = baseURL + "/\(team.Collection)/\(team.Project)/\(team.name)/_api/_teamChart/Burndown?chartOptions=%7B%22Width%22%3A936%2C%22Height%22%3A503%2C%22ShowDetails%22%3Atrue%2C%22Title%22%3A%22%22%7D&counter=2&iterationPath=\(iterationPath)&__v=5"

//        println(route)

        makeHTTPGetRequest(route, onCompletion:  {(data: NSData) in
//            println(data)
            onCompletion(data: data)    //Pass back NSData object with the image contents
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
    
    func countPBIs(State: String, onCompletion: (JSON) -> Void){
        
        let newIteration = self.iterationPath.stringByReplacingOccurrencesOfString("\\", withString: "\\\\", options: NSStringCompareOptions.LiteralSearch, range: nil)

        
        let query = "{\"query\": \"SELECT System.Id FROM WorkItems WHERE [System.WorkItemType] = 'Product Backlog Item'  AND [System.IterationPath] = '\(newIteration)' AND [System.State]= '\(State)'\"}"
//        println(query)
        
        runWIQL(query, onCompletion: { jsonData in
            onCompletion(jsonData)
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
            
            //            let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            onCompletion(json)            //return results from request
        })
    }
    
    func connectToWebAPI(){
        
        //setting up the base64-encoded credentials
        let loginString = NSString(format: "%@:%@", usr, pw)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = "Basic " + loginData.base64EncodedStringWithOptions(nil)
        
        //creating the request
        let route = baseURL + "/\(collection!)/\(projectId!)/_apis/wit/wiql?api-version=2.0"
        let url = NSURL(string: route)
        var request = NSMutableURLRequest(URL: url!)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession.sharedSession()
        request.setValue(base64LoginString, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let urlConnection = NSURLConnection(request: request, delegate: self)
        request.HTTPMethod = "POST"
        
        
        
        let query = "{\"query\": \"SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Product Backlog Item' AND [System.AreaPath] = 'Url2015Project\\\\iOSTeamExplorer' AND [System.IterationPath] = 'Url2015Project\\\\iOS_Team_Explorer_Collection\\\\SP5 - Epics, Features, PBI, Sprints and Work item views'\"}\"}"
        
        request.HTTPBody = query.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if (error != nil) {
                println(error)
                
            }
            else {
                
                
                //                println("Response: " + response)
                
                //                let json:JSON = JSON(data: data, options:NSJSONReadingOptions.MutableContainers, error:nil)
                //                println(json)
                
                let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
//                println(jsonResult)
                
                
            }
        })
        
        
        //fire off the request
        task.resume()
    }
    
    func makeHTTPPostRequest(path: String, bodyContent: String, onCompletion: (data: NSData) -> Void ){
        
        //create the request
        let url = NSURL(string: path)
        var request = NSMutableURLRequest(URL: url!)
        
        let session = NSURLSession.sharedSession()
        request.setValue(buildBase64EncodedCredentials(), forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.HTTPMethod = "POST"
        request.HTTPBody = bodyContent.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if (error != nil) {
                println(error)
            }
            else {
                onCompletion(data: data)                                                            //return data from POST request.
            }
        })
        
        //fire off the request
        task.resume()
    }
    
    
    /**
    @brief: Creates a HTTPOperation as a HTTP POST request and starts it for you.
    
    @param: path The url you would like to make a request to.
    @param: onCompletion The closure that is run when a HTTP Request finished.
    
    @see: makeHTTPPostRequest
    @see: buildAuthorizationHeader
    */
    func makeHTTPGetRequest(path: String, onCompletion: (data: NSData) -> Void ){
        
        var request = buildAuthorizationHeader()
        
        //Make GET request using SwiftHTTP Pod
        request.GET(path, parameters: ["api-version": 2.0], completionHandler: {(response: HTTPResponse) in
            if let err = response.error {
                println("error: \(err.localizedDescription)")
                self.setLastResponseCode(response)
            }
            if let data = response.responseObject as? NSData {
                self.setLastResponseCode(response)
                onCompletion(data: data)                                                            //return data from GET request.
            }
            
        })
    }
    
    func setLastResponseCode(response: HTTPResponse){
        
        if(response.statusCode != nil){
            self.lastResponseCode = String(response.statusCode!)
        }else{
            self.lastResponseCode = "400"
        }
        
    }
    
    /**
    @brief: Creates a HTTPOperation as a HTTP POST request and starts it for you.
    
    @param: usr The user you would use for authentication.
    @param: pw The password you would use for authentication.
    
    @see: makeHTTPGetRequest
    @see: makeHTTPPostRequest
    */
    func buildAuthorizationHeader() -> HTTPTask{
        
        var request = HTTPTask()
        request.requestSerializer = HTTPRequestSerializer()
        request.requestSerializer.headers["Authorization"] = buildBase64EncodedCredentials()             //basic auth header with auth credentials
        return request;
    }
    
    func buildBase64EncodedCredentials() -> String{
        
        //setting up the base64-encoded credentials
        let loginString = NSString(format: "%@:%@", usr, pw)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(nil)
        
        return "Basic " + base64LoginString
    }
}
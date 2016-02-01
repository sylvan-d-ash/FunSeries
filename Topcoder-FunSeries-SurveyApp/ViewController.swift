//
//  ViewController.swift
//  Topcoder-FunSeries-SurveyApp
//
//  Created by Harshit on 24/09/15.
//  Copyright (c) 2015 topcoder. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UISearchDisplayDelegate, NSFetchedResultsControllerDelegate {
    
    var managedObjectContext:NSManagedObjectContext?
    var fetchController:NSFetchedResultsController = NSFetchedResultsController()
    
    var dataArray:NSMutableArray!
    var plistPath:String!
    //    var tableData: NSArray!
    var filteredData: [String] = []
    var titleData :[String] = []
    var i: Int = 0
    var flag: Bool = false;
    var selectedSurvey: Survey?
    
    @IBOutlet var SurveyTableSearchBar: UISearchBar!
    @IBOutlet var SurveyTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SurveyTable.delegate=self;
        SurveyTable.dataSource=self;
        
        let JSONData:NSData = getJSON("http://www.mocky.io/v2/560920cc9665b96e1e69bb46")
        
        if let tableData = parseJSON(JSONData) as? [[String: AnyObject]] {
            Logger.infoFrom(self, message: "Survey data received")
            
            // Updating local store from server
            for item in tableData {
                let req = NSFetchRequest()
                let entity = NSEntityDescription.entityForName("Survey", inManagedObjectContext: self.managedObjectContext!)
                let predTemplate = NSPredicate(format: "id = $SURVEY_ID")
                req.entity = entity
                
                if let surveyid = item["id"] as? Int {
                    let predicate = predTemplate.predicateWithSubstitutionVariables(["SURVEY_ID": surveyid])
                    req.predicate = predicate
                    do {
                        if let results = try self.managedObjectContext?.executeFetchRequest(req) as? [Survey] {
                            var survey:Survey
                            
                            //print(results)
                            Logger.debugFrom(self, message: "\(results)")
                            
                            //fetching the already filled coredata to check if the isdeleted = set to true
                            if results.count == 0 {
                                survey = NSEntityDescription.insertNewObjectForEntityForName("Survey", inManagedObjectContext: self.managedObjectContext!) as! Survey
                                survey.id = item["id"] as? Int
                            } else {
                                survey = results[0]
                                if survey.isdeleted!.boolValue == false {
                                    //
                                    continue
                                }
                            }
                            survey.title = item["title"] as? String
                            survey.desc = item["description"] as? String
                        }
                    }
                    catch let error as NSError {
                        Logger.errorFrom(self, message: "Error \(error.localizedDescription), \(error.userInfo)")
                        abort()
                    }
                }
            }
            // save updates from server
            do {
                try self.managedObjectContext!.save()
            } catch let error as NSError {
                Logger.errorFrom(self, message: "Error \(error.localizedDescription), \(error.userInfo)")
                abort()
            }
            
            
            // Fetching data from local store 
            let request = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("Survey", inManagedObjectContext: self.managedObjectContext!)
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            let predicate = NSPredicate(format:"isdeleted = 0")
            request.predicate = predicate
            request.entity = entity
            request.sortDescriptors = [sortDescriptor]
            
            self.fetchController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.fetchController.delegate = self
            do {
                try self.fetchController.performFetch()
            } catch let error as NSError {
                Logger.errorFrom(self, message: "fetch error: \(error.localizedDescription)")
            }

        }
    }
    
    //Search Bar functions
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String){
        Logger.debugFrom(self, message: "Searching...")
        
        flag = true;
        var predicate:NSPredicate?
        if searchText != "" {
            predicate = NSPredicate(format: "title contains[cd] %@ AND isdeleted = 0", searchText)
        }
        self.fetchController.fetchRequest.predicate = predicate
        
        do {
            try self.fetchController.performFetch()
        } catch let error as NSError {
            Logger.errorFrom(self, message: "fetch error: \(error.localizedDescription)")
        }
        SurveyTable.reloadData()
    }
    
    
    //JSON Parsing and API hit functions
    
    func getJSON(urlToRequest: String) -> NSData {
        Logger.infoFrom(self, message: "Fetching survey data from server")
        
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
    }
    
    func parseJSON(inputData: NSData) -> NSArray{
        Logger.infoFrom(self, message: "Parsing JSON data")
        
        let data: NSArray = (try! NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers)) as! NSArray
        
        return data
    }
    
    
    //SEGUE
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let destinationVC = segue.destinationViewController as! DetailViewController
            destinationVC.descriptionString = self.selectedSurvey?.desc
            destinationVC.selectedSurvey = self.selectedSurvey
            destinationVC.managedObjectContext = self.managedObjectContext
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func numberOfSectionsInTableView(SurveyTable: UITableView) -> Int {
        if let sections =  self.fetchController.sections {
            return sections.count
        }
        return 0
    }
    
    
    func tableView(SurveyTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchedObjects =  self.fetchController.fetchedObjects {
            return fetchedObjects.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let surveys = self.fetchController.fetchedObjects as? [Survey] {
            self.selectedSurvey = surveys[indexPath.row]
            self.performSegueWithIdentifier("showDetail", sender: nil)
        }
    }
    
    func tableView(SurveyTable: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = SurveyTable.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            
        if let surveys = self.fetchController.fetchedObjects as? [Survey] {
            cell.textLabel?.text = surveys[indexPath.row].title
        }
            
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let survey = self.fetchController.objectAtIndexPath(indexPath) as? Survey {
                survey.isdeleted = NSNumber(bool: true)
                
                Logger.debugFrom(self, message: "\(survey.isdeleted)")
                Logger.debugFrom(self, message: "row \(indexPath.row)")
                
                do {
                    try self.managedObjectContext?.save()
                } catch let error as NSError {
                    Logger.errorFrom(self, message: "save error: \(error.localizedDescription)")
                    abort()
                }
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        SurveyTable.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        SurveyTable.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        Logger.debugFrom(self, message: "row: \(indexPath!.row)")
        
        switch(type) {
        case .Update: fallthrough
        case .Delete:
            SurveyTable.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            SurveyTable.reloadData();
            break
        default:
            break
            
        }
    }
    
    
}



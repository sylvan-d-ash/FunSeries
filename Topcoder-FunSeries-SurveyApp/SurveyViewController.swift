//
//  SurveyViewController.swift
//  Topcoder-FunSeries-SurveyApp
//
//  Created by Sylvan .D. Ash on 1/11/16.
//  Copyright © 2016 topcoder. All rights reserved.
//

import UIKit
import CoreData

class SurveyViewController: UIViewController {
    
    /// Reference to the ID of the selected survey
    var surveyId: NSNumber?
    /// Reference to object managing our context
    var managedObjectContext:NSManagedObjectContext?
    /// Array containing questions for selected survey
    var questions: [Question]?
    /// Index of the currently being displayed question
    var currentQuestion: Int = 0
    
    /// Reference to the label for the question number
    @IBOutlet weak var questionNumberLabel: UILabel!
    /// Reference to question text view
    @IBOutlet weak var questionTextView: UITextView!
    /// Reference to answer text field
    @IBOutlet weak var answerTextField: UITextField!
    /// Reference to previous button
    @IBOutlet weak var previousButton: UIButton!
    /// Reference to next button
    @IBOutlet weak var nextButton: UIButton!
    /// Reference to finish button
    @IBOutlet weak var finishButton: UIButton!
    
    /** 
     Setup view controller:
     1. Fetch questions for selected survey
     2. Display first question
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize questions array
        self.questions = []
        
        // Fetch data from coredata
        let req = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Question", inManagedObjectContext: self.managedObjectContext!)
        let predTemplate = NSPredicate(format: "surveyId = $SURVEY_ID")
        let predicate = predTemplate.predicateWithSubstitutionVariables(["SURVEY_ID": self.surveyId!])
        req.entity = entity
        req.predicate = predicate
        
        do {
            if let results = try self.managedObjectContext?.executeFetchRequest(req) as? [Question] {
                
                // Fetch data from server if no questions in coredata and save them to coredata
                if results.count == 0 {
                    /// Questions data from server
                    let JSONData:NSData = getJSON("https://demo2394932.mockable.io/wizard")
                    
                    if let allQuestions = parseJSON(JSONData) as? [[String: AnyObject]] {
                        //print(allQuestions) // show me data
                        
                        for aQuestion in allQuestions {
                            
                            // Create a new question and save it to core data if the survey IDs match
                            if aQuestion["surveyId"] as! Int == self.surveyId {
                                let question = NSEntityDescription.insertNewObjectForEntityForName("Question", inManagedObjectContext: self.managedObjectContext!) as! Question
                                question.id = aQuestion["id"] as? Int
                                question.surveyId = self.surveyId
                                question.desc = aQuestion["question"] as? String
                                
                                // Add the question to our array of questions for this survey
                                self.questions?.append(question)
                            }
                        }
                        
                        // Save updates from server
                        try self.managedObjectContext!.save()
                        
                        // Load first question
                        loadQuestion(currentIndex: self.currentQuestion)
                    }
                } else {
                    self.questions = results
                    
                    // Load first question
                    loadQuestion(currentIndex: self.currentQuestion)
                }
            }
        }
        catch let error as NSError {
            Logger.errorFrom(self, message: "Error \(error.localizedDescription), \(error.userInfo)")
            abort()
        }
    }
    
    
    // MARK: IB Actions
    
    @IBAction func nextQuestion(sender: AnyObject) {
        // Save answer if present
        saveAnswer(currentIndex: self.currentQuestion)
        
        // Navigate to next question
        self.currentQuestion++
        
        if self.currentQuestion < self.questions?.count {
            // Enable Previous button
            if self.currentQuestion == 1 {
                self.previousButton.enabled = true
            }
            loadQuestion(currentIndex: self.currentQuestion)
            
        } else {
            // Display Finish button and disable/hide all the other controls (apart from Previous button)
            self.nextButton.enabled = false
            self.finishButton.hidden = false
            self.answerTextField.hidden = true
            self.questionTextView.hidden = true
            self.questionNumberLabel.hidden = true
        }
    }
    
    @IBAction func previousQuestion(sender: AnyObject) {
        // Save answer, if present
        saveAnswer(currentIndex: self.currentQuestion)
        
        // Navigate to previous question
        self.currentQuestion--
        
        if self.currentQuestion >= 0 {
            Logger.infoFrom(self, message: "Display previous questions")
            
            // Disable Previous button
            if self.currentQuestion == 0 {
                Logger.debugFrom(self, message: "Disable Previous button")
                
                self.previousButton.enabled = false
            }
            
            // Hide Finish button and unhide/enable all the other controls
            if self.currentQuestion == (self.questions?.count)! - 1 {
                Logger.debugFrom(self, message: "Hide Finish button and enable all other controls")
                
                self.nextButton.enabled = true
                self.finishButton.hidden = true
                self.answerTextField.hidden = false
                self.questionTextView.hidden = false
                self.questionNumberLabel.hidden = false
            }
            
            loadQuestion(currentIndex: self.currentQuestion)
        }
    }
    
    @IBAction func finishTapped(sender: AnyObject) {
        Logger.infoFrom(self, message: "Finish button tapped")
    }
    
    
    // MARK: - Private
    
    /**
     Loads a question and its answer if one is present
     
     - parameter currentIndex: The number of the question to display
     */
    func loadQuestion(currentIndex index: Int) {
        if self.questions?.count > 0 {
            Logger.infoFrom(self, message: "Loading question #\(index)")
            
            self.questionNumberLabel.text = String(format: "#%d", index + 1)
            
            let question = self.questions![index]
            self.questionTextView.text = question.desc
            
            if let answer = question.answer {
                self.answerTextField.text = answer
            } else {
                self.answerTextField.text = ""
            }
        } else {
            Logger.warningFrom(self, message: "This survey currently has no questions")
            
            self.questionNumberLabel.text = "-"
            self.questionTextView.text = "This survey currently has no questions"
        }
    }
    
    /**
     Saves the answer given for a question
     
     - parameter currentIndex: The index of the question the answer is for
     */
    func saveAnswer(currentIndex index: Int) -> Void {
        let answer = self.answerTextField.text
        
        // Check if an answer was provided
        if (answer != nil && answer != "") {
            let question = self.questions![index]
            
            if let oldAnswer = question.answer {
                // If old answer and current answer are the same, then do nothing
                if answer == oldAnswer {
                    return
                }
            }
            
            // Save the current answer since there's no answer OR it's not the same as the old answer
            Logger.infoFrom(self, message: "Saving answer")
            
            let req = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("Question", inManagedObjectContext: self.managedObjectContext!)
            let predTemplate = NSPredicate(format: "id = $QUESTION_ID")
            let predicate = predTemplate.predicateWithSubstitutionVariables(["QUESTION_ID": question.id!])
            req.entity = entity
            req.predicate = predicate
            
            do {
                if let results = try self.managedObjectContext?.executeFetchRequest(req) as? [Question] {
                    let _question = results[0]
                    _question.answer = answer
                    
                    // Save update to question
                    try self.managedObjectContext!.save()
                    
                    // Update our question array
                    self.questions![index].answer = answer
                }
            }
            catch let error as NSError {
                Logger.errorFrom(self, message: "Error \(error.localizedDescription), \(error.userInfo)")
                abort()
            }
        }
    }
    
    
    // JSON Parsing and API hit functions
    
    func getJSON(urlToRequest: String) -> NSData {
        Logger.infoFrom(self, message: "Fetching questions data from server...")
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
    }
    
    func parseJSON(inputData: NSData) -> NSArray{
        Logger.infoFrom(self, message: "Parsing questions JSON data")
        
        let data: NSArray = (try! NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers)) as! NSArray
        
        return data
    }
}
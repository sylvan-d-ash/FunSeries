//
//  DetailViewController.swift
//  Topcoder-FunSeries-SurveyApp
//
//  Created by Harshit on 1/6/16.
//  Copyright © 2015 topcoder. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var descriptionString: String?
    var selectedSurvey: Survey?
    var managedObjectContext:NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.textView.text = self.descriptionString
        self.textView.text = self.selectedSurvey?.desc
        
        // TODO: Truncate the title to easily fit in title
        //self.title = self.selectedSurvey?.title
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSurvey" {
            let destinationVC = segue.destinationViewController as! SurveyViewController
            destinationVC.surveyId = self.selectedSurvey?.id
            destinationVC.managedObjectContext = self.managedObjectContext
        }
    }
}
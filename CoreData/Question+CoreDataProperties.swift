//
//  Question+CoreDataProperties.swift
//  Topcoder-FunSeries-SurveyApp
//
//  Created by Sylvan .D. Ash on 1/27/16.
//  Copyright © 2016 topcoder. All rights reserved.
//

import Foundation
import CoreData

extension Question {
    
    @NSManaged var id: NSNumber?
    @NSManaged var surveyId: NSNumber?
    @NSManaged var desc: String?
    @NSManaged var answer: String?
    
}
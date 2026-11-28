//
//  CategoryModel.swift
//  ToDoListUIkit
//
//  Created by mac on 6/8/25.
//

import Foundation
import UIKit

enum Category: String, CaseIterable {
    case work = "work"
    case study = "study"
    case exercise = "exercise"
    
    var color: UIColor {
        switch self {
        case .work:
            return UIColor.workColor
        case .exercise:
            return UIColor.exerciseColor
        case .study:
            return UIColor.studyColor
        }
    }
    
    var secondaryColor: UIColor {
        switch self {
        case .work:
            return UIColor.secondaryworkColor
        case .exercise:
            return UIColor.secondaryexerciseColor
        case .study:
            return UIColor.secondarystudyColor
        }
    }
    
}

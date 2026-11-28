//
//  Extension+UIColor.swift
//  ToDoListUIkit
//
//  Created by mac on 7/9/25.
//

import Foundation
import UIKit

extension UIColor {
    static var workColor: UIColor {
        return UIColor(named: "work")!
    }
    
    static var secondaryworkColor: UIColor {
        return UIColor(named: "work")!.withAlphaComponent(0.2)
    }

    static var exerciseColor: UIColor {
        return UIColor(named: "exercise")!
    }
    
    static var secondaryexerciseColor: UIColor {
        return UIColor(named: "exercise")!.withAlphaComponent(0.2)
    }

    static var studyColor: UIColor {
        return UIColor(named: "study")!
    }
    
    static var secondarystudyColor: UIColor {
        return UIColor(named: "study")!.withAlphaComponent(0.2)
    }
    
    static var secondaryLinkColor: UIColor {
        return UIColor(named: "secondaryLink")!
    }
}

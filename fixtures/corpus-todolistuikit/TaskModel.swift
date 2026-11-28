//
//  TaskModel.swift
//  ToDoListUIkit
//
//  Created by mac on 6/9/25.
//

import Foundation

struct Task {
    
    let id: String
    let category: Category
    let caption: String
    let createdDate: Date
    var isComplete: Bool
}

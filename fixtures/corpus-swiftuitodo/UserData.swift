//
//  UserData.swift
//  SwiftUITodo
//
//  Created by Suyeol Jeon on 03/06/2019.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//
//  Corpus fixture: the 2019 `BindableObject`/`@propertyDelegate` pair was replaced by
//  `ObservableObject`/`@Published` and the `UserDefaultsValue` property wrapper by a
//  plain `UserDefaults` round trip. The stored key and the JSON format are unchanged.
//

import Combine
import Foundation

let defaultTasks: [Task] = [
  Task(title: "Read SwiftUI Documentation 📚", isDone: false),
  Task(title: "Watch WWDC19 Keynote 🎉", isDone: true),
]

final class UserData: ObservableObject {
  @Published var tasks: [Task] {
    didSet {
      let data = try? JSONEncoder().encode(tasks)
      UserDefaults.standard.set(data, forKey: "Tasks")
    }
  }

  init() {
    let data = UserDefaults.standard.data(forKey: "Tasks")
    self.tasks = data.flatMap { try? JSONDecoder().decode([Task].self, from: $0) } ?? defaultTasks
  }
}

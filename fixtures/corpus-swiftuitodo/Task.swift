//
//  Task.swift
//  SwiftUITodo
//
//  Created by Suyeol Jeon on 03/06/2019.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//

import Foundation

struct Task: Equatable, Hashable, Codable, Identifiable {
  let id: UUID
  var title: String
  var isDone: Bool

  init(title: String, isDone: Bool) {
    self.id = UUID()
    self.title = title
    self.isDone = isDone
  }
}

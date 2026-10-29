//
//  TaskListView.swift
//  SwiftUITodo
//
//  Created by Suyeol Jeon on 03/06/2019.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//
//  Corpus fixture: the 2019 SwiftUI beta spellings (`TextField($binding, placeholder:)`,
//  `.navigationBarTitle`, `.navigationBarItems`) were replaced by the current API.
//  The structure of the screen is unchanged.
//

import SwiftUI

struct TaskListView: View {
  @EnvironmentObject var userData: UserData
  @State var draftTitle: String = ""
  @State var isEditing: Bool = false

  var body: some View {
    List {
      TextField("Create a New Task...", text: self.$draftTitle, onCommit: self.createTask)
        .accessibilityIdentifier("task.new")
      ForEach(self.userData.tasks) { task in
        TaskItemView(task: task, isEditing: self.$isEditing)
      }
    }
    .navigationTitle("Tasks 👀")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { self.isEditing.toggle() }) {
          if !self.isEditing {
            Text("Edit")
          } else {
            Text("Done").bold()
          }
        }
        .accessibilityIdentifier("task.edit")
      }
    }
  }

  private func createTask() {
    let title = self.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return }
    let newTask = Task(title: title, isDone: false)
    self.userData.tasks.insert(newTask, at: 0)
    self.draftTitle = ""
  }
}

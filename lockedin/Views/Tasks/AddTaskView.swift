//
//  AddTaskView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//


import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    TextField("Task Description", text: $description)
                }
                
                Section {
                    Button("Save Task") {
                        if title.isEmpty {
                            showAlert = true
                        } else {
                            let newTask = Task.custom(title: title, description: description)
                            taskManager.addTask(newTask)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Custom Task")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Task"),
                    message: Text("Please enter a title for your task."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}


struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView(taskManager: TaskManager())
    }
}



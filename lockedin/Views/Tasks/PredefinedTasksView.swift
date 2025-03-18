//
//  PredefinedTasksView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI
struct PredefinedTasksView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTasks = Set<UUID>()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Tasks to Add")) {
                    ForEach(taskManager.getPredefinedTasks()) { task in
                        PredefinedTaskRow(task: task, isSelected: selectedTasks.contains(task.id)) {
                            if selectedTasks.contains(task.id) {
                                selectedTasks.remove(task.id)
                            } else {
                                selectedTasks.insert(task.id)
                            }
                        }
                    }
                }
                
                if !selectedTasks.isEmpty {
                    Section {
                        Button("Add Selected Tasks") {
                            addSelectedTasks()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Predefined Tasks")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    addSelectedTasks()
                }
                .disabled(selectedTasks.isEmpty)
            )
        }
    }
    
    private func addSelectedTasks() {
        for task in taskManager.getPredefinedTasks() {
            if selectedTasks.contains(task.id) {
                taskManager.addTask(task)
            }
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct PredefinedTaskRow: View {
    let task: Task
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .padding(.vertical, 8)
    }
}

struct PredefinedTasksView_Previews: PreviewProvider {
    static var previews: some View {
        PredefinedTasksView(taskManager: TaskManager())
    }
}

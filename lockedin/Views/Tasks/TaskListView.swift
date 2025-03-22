//
//  TaskListView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI

struct TaskListView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var showingSelectPredefined = false
    @State private var selectedTask: Task? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if taskManager.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListContent
                }
            }
            .navigationTitle("Bloomer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create a Task") {
                            showingAddTask = true
                        }
                        
                        Button("Choose from Existing") {
                            showingSelectPredefined = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Task.self) { task in
                TaskEvidenceView(taskManager: taskManager, task: task)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
            }
            .sheet(isPresented: $showingSelectPredefined) {
                PredefinedTasksView(taskManager: taskManager)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Tasks Added")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add tasks to complete before accessing your apps")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddTask = true
            }) {
                Text("Create a Task")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
            
            Button(action: {
                showingSelectPredefined = true
            }) {
                Text("Choose from Existing")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var taskListContent: some View {
        List {
            Section(header: Text("To-Do")) {
                ForEach(taskManager.tasks.filter { $0.status == .pending }) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task)
                    }
                }
                .onDelete { indexSet in
                    let pendingTasks = taskManager.tasks.filter { $0.status == .pending }
                    let pendingIndices = indexSet.map { pendingTasks[$0] }
                    
                    // Map back to original indices in the full task array
                    let originalIndices = pendingIndices.compactMap { task in
                        taskManager.tasks.firstIndex(where: { $0.id == task.id })
                    }
                    
                    taskManager.removeTask(at: IndexSet(originalIndices))
                }
            }
            
            if !taskManager.tasks.filter({ $0.status != .pending }).isEmpty {
                Section(header: Text("Completed")) {
                    ForEach(taskManager.tasks.filter { $0.status != .pending }) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task)
                        }
                    }
                }
            }
        }
    }
}

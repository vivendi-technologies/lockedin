//
//  TaskListView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI

// Add this at the top level of your file, outside the TaskListView struct
enum TaskError: Error {
    case invalidIndexSet
    case taskNotFound
    case mappingFailed
}

// Add this extension to provide localized descriptions
extension TaskError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidIndexSet:
            return "No tasks were selected for deletion"
        case .taskNotFound:
            return "Could not find the selected task"
        case .mappingFailed:
            return "Failed to map tasks to proper indices"
        }
    }
}

struct TaskListView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var showingSelectPredefined = false
    @State private var selectedTask: Task? = nil
    @State private var errorOccurred = false
    @State private var errorMessage = ""
    // Add state for showing the banner
//    @State private var showingCompletionBanner = false
//    @State private var completedTaskTitle = ""
    
    // Keep track of when we're performing deletion operations
    @State private var isPerformingDeletion = false
    
    var body: some View {
        NavigationStack {
//            ZStack(alignment: .top) {
//                VStack {
//                    if taskManager.tasks.isEmpty {
//                        emptyStateView
//                    } else {
//                        safeTaskListContent
//                    }
//                }
//                
//                // Add the completion banner
//                if showingCompletionBanner {
//                    TaskCompletionBanner(isVisible: $showingCompletionBanner, taskTitle: completedTaskTitle)
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
//                        .zIndex(1) // Ensure it's above all content
//                        .padding(.bottom, 8)
//                }
//            }
            // Replace the ZStack with:
            VStack {
                if taskManager.tasks.isEmpty {
                    emptyStateView
                } else {
                    safeTaskListContent
                }
            }
            .navigationTitle("Today's Tasks")
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
            .alert(isPresented: $errorOccurred) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Listen for task completion notifications
//            .onReceive(taskManager.completionNotifier.$shouldShow) { shouldShow in
//                if shouldShow, let completedTask = taskManager.completionNotifier.lastCompletedTask {
//                    completedTaskTitle = completedTask.title
//                    withAnimation {
//                        showingCompletionBanner = true
//                    }
//                    // Reset the notifier
//                    taskManager.completionNotifier.reset()
//                }
//            }
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
    
    // Safe version with improved error handling
    private var safeTaskListContent: some View {
        List {
            Section(header: Text("To-Do")) {
                ForEach(taskManager.tasks.filter { $0.status == .pending }) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task)
                    }
                    .onDisappear {
                        // Only check for unexpected disappearances if we're not in the middle of a deletion
                        if !isPerformingDeletion {
                            // If the task is gone and we're not deleting, that's unexpected
                            if !taskManager.tasks.contains(where: { $0.id == task.id }) {
                                handleTaskError("Task was removed unexpectedly")
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    // Set the flag before starting deletion
                    isPerformingDeletion = true
                    
                    do {
                        let pendingTasks = taskManager.tasks.filter { $0.status == .pending }
                        
                        // Throw an error if indexSet is empty
                        if indexSet.isEmpty {
                            throw TaskError.invalidIndexSet
                        }
                        
                        // Get tasks to delete and map to original indices
                        let tasksToDelete = indexSet.compactMap { idx -> Task? in
                            guard idx < pendingTasks.count else { return nil }
                            return pendingTasks[idx]
                        }
                        
                        // Throw an error if no tasks were found
                        if tasksToDelete.isEmpty {
                            throw TaskError.taskNotFound
                        }
                        
                        let originalIndices = tasksToDelete.compactMap { task in
                            taskManager.tasks.firstIndex(where: { $0.id == task.id })
                        }
                        
                        // Throw an error if mapping failed
                        if originalIndices.isEmpty {
                            throw TaskError.mappingFailed
                        }
                        
                        // Remove tasks
                        taskManager.removeTask(at: IndexSet(originalIndices))
                    } catch {
                        handleTaskError("Error removing task: \(error.localizedDescription)")
                    }
                    
                    // Reset the flag after a short delay to allow UI updates to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPerformingDeletion = false
                    }
                }
            }
            
            if !taskManager.tasks.filter({ $0.status != .pending }).isEmpty {
                Section(header: Text("Completed")) {
                    ForEach(taskManager.tasks.filter { $0.status != .pending }) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task)
                        }
                        .onDisappear {
                            // Only check for unexpected disappearances if we're not in the middle of a deletion
                            if !isPerformingDeletion {
                                // If the task is gone and we're not deleting, that's unexpected
                                if !taskManager.tasks.contains(where: { $0.id == task.id }) {
                                    handleTaskError("Task was removed unexpectedly")
                                }
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            // Force refresh data to ensure UI is in sync
            DispatchQueue.main.async {
                taskManager.saveTasks()
            }
        }
    }
    
    // Helper to handle errors
    private func handleTaskError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.errorOccurred = true
        }
    }
}

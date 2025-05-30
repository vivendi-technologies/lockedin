//
//  TaskManager.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import Foundation
import SwiftUI

// Class to manage the collection of tasks
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completionNotifier = TaskCompletionNotification()
    
    // Using the injected reference:
    var appRestrictionManager: AppRestrictionManager?
    
    // REMOVE THIS TIMER - it's causing problems
    // private var taskCompletionCheckTimer: Timer?
    
    // Predefined tasks that the app will offer
    private let predefinedTasks: [Task] = [
        .predefined(title: "Morning Meditation", description: "Complete a 10-minute meditation session"),
        .predefined(title: "Read", description: "Read at least 10 pages of a book"),
        .predefined(title: "Exercise", description: "Complete 30 minutes of physical activity"),
        .predefined(title: "Journaling", description: "Write in your journal for at least 5 minutes"),
        .predefined(title: "Learn", description: "Study a new skill for 20 minutes"),
        .predefined(title: "Hydrate", description: "Drink a glass of water"),
        .predefined(title: "Gratitude", description: "Write down three things you're grateful for"),
        .predefined(title: "Plan", description: "Review and update your to-do list for the day")
    ]
    
    init() {
        loadTasks()
        // REMOVE TIMER SETUP - no more timers!
        // setupTaskCompletionTimer()
        
        // Instead, check status once at startup
        checkAllTasksCompletion()
    }
    
    // MARK: - Task Management
    
    func getPredefinedTasks() -> [Task] {
        return predefinedTasks
    }
    
    func addTask(_ task: Task) {
        DispatchQueue.main.async {
            self.tasks.append(task)
            self.saveTasks()
            
            // Only check restriction state if the new task is pending
            if task.status == .pending {
                print("New pending task added - directly enabling restrictions")
                self.appRestrictionManager?.enableRestrictions(preserveSelection: true)
            }
        }
    }
    
    func removeTask(at indexSet: IndexSet) {
        DispatchQueue.main.async {
            self.tasks.remove(atOffsets: indexSet)
            self.saveTasks()
            
            // Check task completion status after removing task(s)
            self.checkAllTasksCompletion()
        }
    }
    
    func updateTask(_ task: Task) {
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                self.tasks[index] = task
                self.saveTasks()
                
                // Check task completion status after updating a task
                self.checkAllTasksCompletion()
            }
        }
    }
    
    // Check if all tasks are completed - no more timers!
    private func checkAllTasksCompletion() {
        let pendingTasks = tasks.filter { $0.status == .pending }
        
        if tasks.isEmpty || pendingTasks.isEmpty {
            // All tasks completed or no tasks - disable restrictions
            print("checkAllTasksCompletion: No pending tasks - disabling restrictions")
            appRestrictionManager?.disableRestrictions()
        } else {
            // Some tasks are still pending - ensure restrictions are active
            print("checkAllTasksCompletion: Pending tasks exist - enabling restrictions")
            appRestrictionManager?.enableRestrictions(preserveSelection: true)
        }
    }
    
    func completeTask(id: UUID, textDescription: String? = nil, imageData: UIImage? = nil) {
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == id }) {
                // Handle image storage
                var imageFilename: String? = nil
                if let image = imageData {
                    imageFilename = FileUtility.saveImage(image, id: UUID())
                }
                
                // Create evidence with proper file storage
                let evidence = TaskEvidence(textDescription: textDescription, imageFilename: imageFilename)
                
                // Update task
                self.tasks[index].evidence = evidence
                self.tasks[index].status = .completed
                self.tasks[index].completionDate = Date()
                
                // Save changes
                self.saveTasks()
                
                // Trigger the completion notification
                self.completionNotifier.notifyCompleted(self.tasks[index])
                
                // Check if all tasks are completed - directly check, no timers
                let pendingTasks = self.tasks.filter { $0.status == .pending }
                if pendingTasks.isEmpty {
                    // All tasks completed - disable restrictions
                    print("completeTask: All tasks completed - disabling restrictions")
                    self.appRestrictionManager?.disableRestrictions()
                }
            }
        }
    }
    
    func updateTaskEvidence(id: UUID, textDescription: String? = nil, imageData: UIImage? = nil) {
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == id }) {
                // Remember original data
                let originalCompletionDate = self.tasks[index].completionDate
                let originalStatus = self.tasks[index].status
                let oldImageFilename = self.tasks[index].evidence?.imageFilename
                
                // Handle image storage - delete old image if replacing it
                var imageFilename = oldImageFilename
                if let image = imageData {
                    // Save new image
                    imageFilename = FileUtility.saveImage(image, id: UUID())
                    
                    // Delete old image if it exists and we're replacing it
                    if let oldFilename = oldImageFilename {
                        FileUtility.deleteImage(filename: oldFilename)
                    }
                } else if imageData == nil && oldImageFilename != nil {
                    // If we're clearing the image
                    if let oldFilename = oldImageFilename {
                        FileUtility.deleteImage(filename: oldFilename)
                    }
                    imageFilename = nil
                }
                
                // Update the evidence
                self.tasks[index].evidence = TaskEvidence(textDescription: textDescription, imageFilename: imageFilename)
                
                // Restore original completion date and status
                self.tasks[index].completionDate = originalCompletionDate
                self.tasks[index].status = originalStatus
                
                self.saveTasks()
            }
        }
    }
    
    // Improved version that preserves task IDs to prevent navigation issues
    // Returns the count of tasks that were reset
    func resetAllTasks() -> Int {
        var resetCount = 0
        
        DispatchQueue.main.async {
            // Safety check - make a copy of the current tasks
            let currentTasks = self.tasks
            
            // If current task list is empty, don't reset
            if currentTasks.isEmpty {
                print("No tasks to reset")
                return
            }
            
            // Reset task status but PRESERVE the same task IDs for navigation
            var updatedTasks: [Task] = []
            
            for task in currentTasks {
                // Skip tasks that are already pending
                if task.status == .pending {
                    updatedTasks.append(task)
                    continue
                }
                
                // Create a reset version of the task with SAME ID but reset status
                let resetTask = Task(
                    id: task.id, // Keep the same ID
                    title: task.title,
                    description: task.description,
                    type: task.type,
                    status: .pending,
                    evidence: nil,
                    creationDate: Date()
                )
                
                // This task was reset
                resetCount += 1
                
                // Add the reset task to our updated collection
                updatedTasks.append(resetTask)
            }
            
            // Safely delete task evidence images
            for task in currentTasks {
                if let imageFilename = task.evidence?.imageFilename {
                    FileUtility.deleteImage(filename: imageFilename)
                }
            }
            
            // Only update tasks if we actually reset something
            if resetCount > 0 {
                // Replace the tasks array on the main thread
                self.tasks = updatedTasks
                self.saveTasks()
                
                // Make sure restrictions are enabled since we now have pending tasks
                if !self.tasks.isEmpty {
                    self.appRestrictionManager?.enableRestrictions()
                }
                
                print("\(resetCount) tasks reset to pending status")
            } else {
                print("No completed tasks to reset")
            }
        }
        
        return resetCount
    }
    
    func cleanupOrphanedImages() {
        // Get list of all image filenames in use
        let usedFilenames = tasks.compactMap { $0.evidence?.imageFilename }
        
        // Get all image files in documents directory
        let documentsURL = FileUtility.getDocumentsDirectory()
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }
        
        // Delete any image that's not referenced by a task
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent
            if filename.hasSuffix(".jpg") && !usedFilenames.contains(filename) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Persistence
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "SavedTasks")
        }
    }
    
    private func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "SavedTasks") {
            if let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasks) {
                // Handle migrating tasks from old schema that may include verified status
                let migratedTasks = decodedTasks.map { task -> Task in
                    var updatedTask = task
                    // Convert any tasks with status other than pending to completed
                    if updatedTask.status != .pending {
                        updatedTask.status = .completed
                    }
                    return updatedTask
                }
                
                tasks = migratedTasks
                return
            }
        }
        
        // Initialize with empty array if no saved tasks
        tasks = []
    }
    
    func resetAllData() {
        DispatchQueue.main.async {
            // Delete all image files
            for task in self.tasks {
                if let imageFilename = task.evidence?.imageFilename {
                    FileUtility.deleteImage(filename: imageFilename)
                }
            }
            
            // Clear tasks array
            self.tasks = []
            
            // Save empty tasks array
            self.saveTasks()
        }
    }
    
    deinit {
    }
}

// Add publisher for task completion
class TaskCompletionNotification: ObservableObject {
    @Published var lastCompletedTask: Task?
    @Published var shouldShow: Bool = false
    
    func notifyCompleted(_ task: Task) {
        lastCompletedTask = task
        shouldShow = true
    }
    
    func reset() {
        shouldShow = false
    }
}

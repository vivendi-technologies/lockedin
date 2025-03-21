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
    
    // Using the injected reference:
    var appRestrictionManager: AppRestrictionManager?
    
    // Remove this line since we're using the injected version instead:
    // @Published var restrictionManager = AppRestrictionManager()
    
    private var taskCompletionCheckTimer: Timer?
    
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
        setupTaskCompletionTimer()
    }
    
    private func setupTaskCompletionTimer() {
        taskCompletionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Use the injected appRestrictionManager instead
            self.appRestrictionManager?.checkTaskCompletion(tasks: self.tasks)
        }
    }
    
    // MARK: - Task Management
    
    func getPredefinedTasks() -> [Task] {
        return predefinedTasks
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func removeTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func completeTask(id: UUID, textDescription: String? = nil, imageData: Data? = nil) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].complete(textDescription: textDescription, imageData: imageData)
            saveTasks()
            
            // Add nil check for optional appRestrictionManager
            appRestrictionManager?.enableRestrictions()
        }
    }
    
    func updateTaskEvidence(id: UUID, textDescription: String? = nil, imageData: Data? = nil) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            // Update the evidence while preserving the completion date and status
            let originalCompletionDate = tasks[index].completionDate
            let originalStatus = tasks[index].status
            
            // Update the evidence
            tasks[index].evidence = TaskEvidence(textDescription: textDescription, imageData: imageData)
            
            // Restore original completion date and status
            tasks[index].completionDate = originalCompletionDate
            tasks[index].status = originalStatus
            
            saveTasks()
        }
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "SavedTasks")
        }
    }
    
    private func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "SavedTasks") {
            if let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasks) {
                tasks = decodedTasks
                return
            }
        }
        
        // Initialize with empty array if no saved tasks
        tasks = []
    }
    
    deinit {
        taskCompletionCheckTimer?.invalidate()
    }
}

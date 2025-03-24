//
//  RegularlyScheduledTask.swift
//  lockedin
//
//  Created by Kevin Le on 3/24/25.
//


//
//  RegularlyScheduledTask.swift
//  lockedin
//
//  Created by Claude on 3/24/25.
//

import Foundation
import BackgroundTasks
import SwiftUI

class RegularlyScheduledTask {
    static let shared = RegularlyScheduledTask()
    
    private let midnightTaskIdentifier = "com.vivendi.lockedin.midnightReset"
    
    // Configure the background task system
    func configureBackgroundTask() {
        // Register task handler for midnight reset
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: midnightTaskIdentifier,
            using: nil) { task in
                // This task will be executed at scheduled times
                self.handleMidnightReset(task: task as! BGProcessingTask)
            }
    }
    
    // Schedule the next midnight reset task
    func scheduleMidnightReset() {
        let request = BGProcessingTaskRequest(identifier: midnightTaskIdentifier)
        
        // Request can be executed as early as midnight
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1 // Tomorrow
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        if let midnight = calendar.date(from: components) {
            // Set earliest begin date to midnight
            request.earliestBeginDate = midnight
            
            // High priority - important for app functionality
            request.requiresNetworkConnectivity = false
            request.requiresExternalPower = false
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("🔄 Scheduled background task for midnight: \(midnight)")
            } catch {
                print("❌ Could not schedule background task: \(error.localizedDescription)")
            }
        }
    }
    
    // Handle the midnight reset task
    private func handleMidnightReset(task: BGProcessingTask) {
        // Keep track of completion
        var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        
        // Request extra time if needed
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            // Background task timeout handler
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // Use shared instances to execute the reset
        let taskManager = (UIApplication.shared.delegate as? AppDelegate)?.taskManager
        let appRestrictionManager = taskManager?.appRestrictionManager
        
        // Create expiration handler
        task.expirationHandler = {
            // End the task if it runs too long
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            task.setTaskCompleted(success: false)
        }
        
        // Perform the actual reset
        if let taskManager = taskManager {
            let resetCount = taskManager.resetAllTasks()
            print("🌙 Midnight background task reset \(resetCount) tasks")
            
            // Re-enable restrictions if needed
            if resetCount > 0, let appRestrictionManager = appRestrictionManager {
                appRestrictionManager.enableRestrictions()
                print("🔒 Re-enabled restrictions in background")
            }
            
            // Update last reset date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let today = dateFormatter.string(from: Date())
            UserDefaults.standard.set(today, forKey: "LastResetDate")
        }
        
        // Schedule next midnight reset
        self.scheduleMidnightReset()
        
        // Mark task complete
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        task.setTaskCompleted(success: true)
    }
    
    // Call this from your AppDelegate to start the system
    func startBackgroundTaskScheduling() {
        // Cancel any existing tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: midnightTaskIdentifier)
        
        // Schedule the next midnight reset
        scheduleMidnightReset()
        
        print("📅 Background midnight reset scheduling started")
    }
}

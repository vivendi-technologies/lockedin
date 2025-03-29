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
    
    let midnightTaskIdentifier = "com.vivendi.lockedin.midnightReset"
    
    func configureBackgroundTask() {
        // Registration is now fully handled in AppDelegate
        print("Background task configuration set up - registration handled by AppDelegate")
    }
    
    // Update the scheduleMidnightReset method in RegularlyScheduledTask.swift
    func scheduleMidnightReset() {
        let request = BGProcessingTaskRequest(identifier: midnightTaskIdentifier)
        
        // Request can be executed as early as midnight
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1 // Tomorrow
        components.hour = 0
        components.minute = 0
        components.second = 5 // Small delay after midnight
        
        if let midnight = calendar.date(from: components) {
            // Set earliest begin date to midnight
            request.earliestBeginDate = midnight
            
            // Make sure we don't require any conditions that might prevent execution
            request.requiresNetworkConnectivity = false
            request.requiresExternalPower = false
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("🔄 Scheduled background task for midnight: \(midnight)")
                
                // Add redundancy - schedule multiple tasks with slightly different times
                // Schedule a backup task 5 minutes after midnight
                let backupRequest = BGProcessingTaskRequest(identifier: midnightTaskIdentifier)
                components.minute = 5
                if let backupTime = calendar.date(from: components) {
                    backupRequest.earliestBeginDate = backupTime
                    backupRequest.requiresNetworkConnectivity = false
                    backupRequest.requiresExternalPower = false
                    try BGTaskScheduler.shared.submit(backupRequest)
                    print("🔄 Scheduled backup background task for: \(backupTime)")
                }
            } catch {
                print("❌ Could not schedule background task: \(error.localizedDescription)")
            }
        }
    }
    
    // Update the handleMidnightReset method in RegularlyScheduledTask.swift
    func handleMidnightReset(task: BGProcessingTask) {
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
                // Important: Preserve user's app selection
                appRestrictionManager.enableRestrictions(preserveSelection: true)
                print("🔒 Re-enabled restrictions in background (preserving app selection)")
                
                // Store a flag to show the reset banner next time the app opens
                UserDefaults.standard.set(true, forKey: "ShouldShowResetBanner")
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

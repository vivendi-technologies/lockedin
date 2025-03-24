//
//  AppDelegate.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//  Updated by Claude on 3/24/25.
//

import SwiftUI
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    // Create a task manager for the app delegate
    let taskManager = TaskManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background tasks
        registerBackgroundTasks()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up orphaned image files when the app terminates
        taskManager.cleanupOrphanedImages()
    }
    
    // Register background tasks for midnight reset
    private func registerBackgroundTasks() {
        // Set up the regularly scheduled task
        RegularlyScheduledTask.shared.configureBackgroundTask()
        
        // Start the scheduling
        RegularlyScheduledTask.shared.startBackgroundTaskScheduling()
    }
    
    // Handle background task completion
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // Process background fetching
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Check if any tasks need to be reset
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if let lastResetDate = UserDefaults.standard.string(forKey: "LastResetDate"),
           lastResetDate != today {
            // Day has changed since last reset, perform a reset
            let resetCount = taskManager.resetAllTasks()
            
            // Re-enable restrictions if needed
            if resetCount > 0 {
                taskManager.appRestrictionManager?.enableRestrictions()
                print("Background fetch: Re-enabled restrictions after resetting \(resetCount) tasks")
                
                // Update the last reset date
                UserDefaults.standard.set(today, forKey: "LastResetDate")
                
                completionHandler(.newData)
                return
            }
        }
        
        completionHandler(.noData)
    }
}

import UIKit
import BackgroundTasks
import SwiftUI

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
        // IMPORTANT: Only register each identifier once
        // Register for background processing task for midnight reset
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: RegularlyScheduledTask.shared.midnightTaskIdentifier,
            using: nil) { task in
                self.handleMidnightReset(task: task as! BGProcessingTask)
        }
        
        // Register app refresh task
        let appRefreshIdentifier = "com.vivendi.lockedin.appRefresh"
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshIdentifier,
            using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Schedule both types of tasks
        RegularlyScheduledTask.shared.startBackgroundTaskScheduling()
        scheduleAppRefresh()
    }
    
    // Handle existing midnight reset (already defined in RegularlyScheduledTask)
    private func handleMidnightReset(task: BGProcessingTask) {
        // You can delegate to the existing implementation or include the logic here
        RegularlyScheduledTask.shared.handleMidnightReset(task: task)
    }
    
    // New method to handle app refresh tasks
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Create a task request for the next refresh
        scheduleAppRefresh()
        
        // Check if tasks need to be reset
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if let lastResetDate = UserDefaults.standard.string(forKey: "LastResetDate"),
           lastResetDate != today {
            // Day has changed since last reset, perform a reset
            let resetCount = taskManager.resetAllTasks()
            
            // Re-enable restrictions if needed, preserving selection
            if resetCount > 0 {
                taskManager.appRestrictionManager?.enableRestrictions(preserveSelection: true)
                UserDefaults.standard.set(true, forKey: "ShouldShowResetBanner")
                UserDefaults.standard.set(today, forKey: "LastResetDate")
                
                task.setTaskCompleted(success: true)
                return
            }
        }
        
        task.setTaskCompleted(success: false)
    }
    
    // Method to schedule app refresh
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.vivendi.lockedin.appRefresh")
        
        // Calculate time for next check
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0  // Midnight
        components.minute = 10 // 10 minutes after midnight
        
        if let targetDate = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            request.earliestBeginDate = targetDate
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("Scheduled app refresh task for: \(targetDate)")
            } catch {
                print("Could not schedule app refresh: \(error)")
            }
        }
    }
    
    // Handle background task completion
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

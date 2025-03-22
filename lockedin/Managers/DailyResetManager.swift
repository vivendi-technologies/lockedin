//
//  DailyResetManager.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//

import Foundation
import SwiftUI

class DailyResetManager: ObservableObject {
    // Reference to the task manager
    private weak var taskManager: TaskManager?
    
    // Published properties
    @Published var didResetToday = false
    @Published var isDailyResetEnabled = true
    
    // Keys for UserDefaults
    private let lastResetDateKey = "LastResetDate"
    private let enableDailyResetKey = "EnableDailyReset"
    
    // Scheduler for midnight reset
    private var resetTimer: Timer?
    
    init() {
        // Load settings
        isDailyResetEnabled = UserDefaults.standard.bool(forKey: enableDailyResetKey)
        
        // Default to true if not set
        if (UserDefaults.standard.object(forKey: enableDailyResetKey) == nil) {
            isDailyResetEnabled = true
            UserDefaults.standard.set(true, forKey: enableDailyResetKey)
        }
        
        // Set up observers
        setupAppStateObserver()
    }
    
    // Connect the task manager
    func setTaskManager(_ taskManager: TaskManager) {
        self.taskManager = taskManager
        
        // Check immediately for reset needs
        DispatchQueue.main.async {
            self.forceCheckDateBasedReset()
            
            // Schedule next reset
            if self.isDailyResetEnabled {
                self.scheduleNextReset()
            }
        }
    }
    
    // MUCH simpler check for date-based reset
    // This just compares the date part of "now" with the date part of "last reset"
    private func forceCheckDateBasedReset() {
        // Only check if enabled
        guard isDailyResetEnabled else { return }
        
        // Get current date string (YYYY-MM-DD format)
        let today = formatDateToString(Date())
        
        // Get last reset date string
        let lastResetDate = UserDefaults.standard.string(forKey: lastResetDateKey) ?? ""
        
        // If no last reset date or it's different from today, reset tasks
        if lastResetDate.isEmpty {
            // First time - just save today
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
            print("First launch - setting initial reset date: \(today)")
        }
        else if lastResetDate != today {
            print("Date changed from \(lastResetDate) to \(today) - resetting tasks")
            resetTasks()
        }
        else {
            print("No reset needed - last reset was today: \(lastResetDate)")
        }
    }
    
    // Convert Date to simple YYYY-MM-DD string
    private func formatDateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Schedule the next reset at midnight
    private func scheduleNextReset() {
        // Only schedule if enabled
        guard isDailyResetEnabled else { return }
        
        // Cancel any existing timer
        resetTimer?.invalidate()
        
        // Calculate time until next midnight
        let now = Date()
        let calendar = Calendar.current
        
        // Get tomorrow's date components
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1  // Next day
        components.hour = 0
        components.minute = 0
        components.second = 5 // Adding a few seconds after midnight to be safe
        
        guard let midnight = calendar.date(from: components) else {
            print("Failed to calculate midnight")
            return
        }
        
        // Calculate interval until midnight
        let interval = midnight.timeIntervalSince(now)
        
        print("Next reset scheduled for: \(midnight), which is \(interval) seconds from now")
        
        // Schedule timer
        resetTimer = Timer(timeInterval: interval, target: self, selector: #selector(resetTimerFired), userInfo: nil, repeats: false)
        if let timer = resetTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // Timer fired method
    @objc private func resetTimerFired() {
        print("Reset timer fired at: \(Date())")
        
        // Double check if enabled
        guard isDailyResetEnabled else { return }
        
        // Reset on main thread
        DispatchQueue.main.async {
            // Reset tasks
            self.resetTasks()
            
            // Schedule the next reset
            self.scheduleNextReset()
        }
    }
    
    // Reset all tasks
    func resetTasks() {
        guard let taskManager = taskManager else {
            print("TaskManager not connected to DailyResetManager")
            return
        }
        
        // Reset all tasks on main thread
        DispatchQueue.main.async {
            // Reset all tasks
            let resetCount = taskManager.resetAllTasks()
            
            // Update last reset date - use simple string for reliable comparison
            let today = self.formatDateToString(Date())
            UserDefaults.standard.set(today, forKey: self.lastResetDateKey)
            
            print("Tasks reset for new day: \(today) - \(resetCount) tasks reset")
            
            // Only show notification if tasks were actually reset
            if resetCount > 0 {
                self.didResetToday = true
                
                // Auto-hide notification after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.didResetToday = false
                }
            }
        }
    }
    
    // Setup observers for app state changes
    private func setupAppStateObserver() {
        // App becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // App entering foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
        
        // App finishing launching
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    // Handle app state changes
    @objc private func appBecameActive(notification: Notification) {
        print("App state changed: \(notification.name.rawValue) at \(Date())")
        forceCheckDateBasedReset()
    }
    
    // Enable or disable daily reset
    func setDailyResetEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.isDailyResetEnabled = enabled
            
            if enabled {
                // Schedule next reset
                self.scheduleNextReset()
            } else {
                // Cancel scheduled reset
                self.resetTimer?.invalidate()
                self.resetTimer = nil
            }
            
            // Save setting
            UserDefaults.standard.set(enabled, forKey: self.enableDailyResetKey)
        }
    }
    
    // Debug helper
    func printResetDebugInfo() {
        let now = Date()
        let today = formatDateToString(now)
        
        print("--- RESET MANAGER DEBUG INFO ---")
        print("Current time: \(now)")
        print("Today as string: \(today)")
        
        if let lastResetDate = UserDefaults.standard.string(forKey: lastResetDateKey) {
            print("Last reset date: \(lastResetDate)")
            print("Reset needed: \(lastResetDate != today ? "YES" : "NO")")
        } else {
            print("No last reset date found")
        }
        
        print("Daily reset enabled: \(isDailyResetEnabled)")
        
        // Task info
        if let taskManager = taskManager {
            let totalTasks = taskManager.tasks.count
            let pendingTasks = taskManager.tasks.filter { $0.status == .pending }.count
            let completedTasks = taskManager.tasks.filter { $0.status != .pending }.count
            
            print("Total tasks: \(totalTasks)")
            print("Pending tasks: \(pendingTasks)")
            print("Completed tasks: \(completedTasks)")
        } else {
            print("TaskManager not connected")
        }
        print("--------------------------------")
    }
    
    // Force reset with debug
    func forceResetWithDebug() {
        print("Forcing task reset")
        printResetDebugInfo()
        resetTasks()
        
        // Print after reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("After reset:")
            self.printResetDebugInfo()
        }
    }
    
    deinit {
        resetTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

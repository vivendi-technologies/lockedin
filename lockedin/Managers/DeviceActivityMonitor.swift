//
//  DeviceActivityMonitor.swift
//  lockedin
//
//  Created by Kevin John Le on 3/24/25.
//

import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

// MARK: - Schedule for midnight transitions
extension DeviceActivityName {
    static let daily = DeviceActivityName("daily")
}

// MARK: - Intervals throughout the day
extension DeviceActivitySchedule {
    static let dailyReset: DeviceActivitySchedule = {
        // Schedule for midnight transition
        // Start 10 seconds before midnight
        let midnight = DateComponents(hour: 23, minute: 45)
        // End 10 seconds after midnight
        let afterMidnight = DateComponents(hour: 0, minute: 15)
        
        return DeviceActivitySchedule(
            intervalStart: midnight,
            intervalEnd: afterMidnight,
            repeats: true
        )
    }()
}

// MARK: - Device Activity Monitor Center
class DeviceActivityMonitorCenter {
    static let shared = DeviceActivityMonitorCenter()
    
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    // Update the startMonitoring method in DeviceActivityMonitorCenter
    func startMonitoring() {
        print("🌙 Starting midnight monitoring schedule")
        
        // First check if authorized
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            print("⚠️ Cannot start monitoring - FamilyControls not authorized")
            return
        }
        
        // Stop any existing monitoring
        stopMonitoring()
        
        do {
            // Create a broader window around midnight to ensure the event is caught
            // Schedule for daily transitions with wider window (11:45 PM - 12:15 AM)
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 23, minute: 45),
                intervalEnd: DateComponents(hour: 0, minute: 15),
                repeats: true
            )
            
            // Start monitoring with the new schedule
            try center.startMonitoring(.daily, during: schedule)
            print("✅ Successfully scheduled midnight monitoring")
            
            // Record that we've set up monitoring
            UserDefaults.standard.set(true, forKey: "DeviceActivityMonitoringEnabled")
        } catch {
            print("❌ Failed to start monitoring: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        center.stopMonitoring([.daily])
    }
}

// MARK: - Device Activity Event Monitor
class DeviceActivityEventMonitor: DeviceActivityMonitor {
    // Use weak references to avoid retain cycles
    private weak var taskManager: TaskManager?
    private weak var appRestrictionManager: AppRestrictionManager?
    
    init(taskManager: TaskManager, appRestrictionManager: AppRestrictionManager) {
        self.taskManager = taskManager
        self.appRestrictionManager = appRestrictionManager
        super.init()
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .daily {
            print("🕛 Midnight transition started")
            
            // This code runs right before midnight
            // We'll prepare for the upcoming reset
            DispatchQueue.main.async {
                // Do any pre-midnight preparation here
            }
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        if activity == .daily {
            print("🌅 Midnight transition completed")
            
            // This code runs right after midnight
            DispatchQueue.main.async {
                // Reset the tasks
                guard let taskManager = self.taskManager,
                      let appRestrictionManager = self.appRestrictionManager else {
                    print("⚠️ TaskManager or AppRestrictionManager not available")
                    return
                }
                
                let resetCount = taskManager.resetAllTasks()
                print("Reset \(resetCount) tasks at midnight")
                
                // Re-enable restrictions if needed, but preserve the user's selection
                if resetCount > 0 {
                    appRestrictionManager.enableRestrictions(preserveSelection: true)
                    print("Re-enabled restrictions after midnight reset (preserving app selection)")
                    
                    // Store a flag to show the reset banner next time the app opens
                    UserDefaults.standard.set(true, forKey: "ShouldShowResetBanner")
                }
                
                // Update last reset date in UserDefaults
                let today = DateFormatter.localizedString(
                    from: Date(),
                    dateStyle: .short,
                    timeStyle: .none
                )
                UserDefaults.standard.set(today, forKey: "LastResetDate")
            }
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Not used in this implementation
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        // Not used in this implementation
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        // Not used in this implementation
    }
}

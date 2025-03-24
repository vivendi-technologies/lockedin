//
//  lockedinApp.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//  Updated by Claude on 3/24/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity

@main
struct lockedinApp: App {
    // Connect the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    @StateObject private var taskManager = TaskManager()
    @StateObject private var appRestrictionManager = AppRestrictionManager()
    @StateObject private var dailyResetManager = DailyResetManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(appRestrictionManager)
                .environmentObject(dailyResetManager)
                .onAppear {
                    // Connect the TaskManager to the AppRestrictionManager
                    taskManager.appRestrictionManager = appRestrictionManager
                    
                    // Set up DeviceActivity monitoring in AppRestrictionManager
                    appRestrictionManager.setTaskManager(taskManager)
                    
                    // Connect the AppDelegate TaskManager to the app restriction manager
                    appDelegate.taskManager.appRestrictionManager = appRestrictionManager
                    
                    // Connect the TaskManager to the DailyResetManager
                    dailyResetManager.setTaskManager(taskManager)
                    
                    // Ensure we have the correct app state
                    print("App launched - checking task state and app restrictions")
                    let pendingTasks = taskManager.tasks.filter { $0.status == .pending }
                    if !pendingTasks.isEmpty && !appRestrictionManager.isRestrictionActive {
                        // We have pending tasks but restrictions aren't active - fix it
                        print("Fixing restriction state - enabling restrictions")
                        appRestrictionManager.enableRestrictions()
                    } else if pendingTasks.isEmpty && appRestrictionManager.isRestrictionActive {
                        // No pending tasks but restrictions are active - fix it
                        print("Fixing restriction state - disabling restrictions")
                        appRestrictionManager.disableRestrictions()
                    }
                    
                    // Ensure DeviceActivity monitoring is set up
                    if appRestrictionManager.isAuthorized {
                        appRestrictionManager.setupDeviceActivityMonitoring()
                    }
                }
        }
    }
}

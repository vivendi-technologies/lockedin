//
//  lockedinApp.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI
import FamilyControls

@main
struct lockedinApp: App {
    // Connect the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    @StateObject private var taskManager = TaskManager()
    @StateObject private var appRestrictionManager = AppRestrictionManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(appRestrictionManager)
                .onAppear {
                    // Connect the TaskManager to the AppRestrictionManager
                    taskManager.appRestrictionManager = appRestrictionManager
                    
                    // Connect the AppDelegate TaskManager to the app restriction manager
                    appDelegate.taskManager.appRestrictionManager = appRestrictionManager
                }
        }
    }
}

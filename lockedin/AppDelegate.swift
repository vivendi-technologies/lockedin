//
//  AppDelegate.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//

import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    // Create a task manager for the app delegate
    let taskManager = TaskManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up orphaned image files when the app terminates
        taskManager.cleanupOrphanedImages()
    }
}

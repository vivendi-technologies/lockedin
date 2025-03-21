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
    @StateObject private var taskManager = TaskManager()
    @StateObject private var appRestrictionManager = AppRestrictionManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(appRestrictionManager)
        }
    }
}

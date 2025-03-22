//
//  DebugViewController.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//


//
//  DebugViewController.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//

import SwiftUI

struct DebugViewController: View {
    @ObservedObject var dailyResetManager: DailyResetManager
    @ObservedObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    // Get last reset date
    private var lastResetDate: String {
        if let date = UserDefaults.standard.string(forKey: "LastResetDate") {
            return date
        }
        return "Not set"
    }
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Information")) {
                    HStack {
                        Text("Current Date:")
                        Spacer()
                        Text(dateFormatter.string(from: Date()))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Last Reset Date:")
                        Spacer()
                        Text(lastResetDate)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Reset Enabled:")
                        Spacer()
                        Text(dailyResetManager.isDailyResetEnabled ? "Yes" : "No")
                            .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Task Status")) {
                    HStack {
                        Text("Total Tasks:")
                        Spacer()
                        Text("\(taskManager.tasks.count)")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Pending Tasks:")
                        Spacer()
                        Text("\(taskManager.tasks.filter { $0.status == .pending }.count)")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Completed Tasks:")
                        Spacer()
                        Text("\(taskManager.tasks.filter { $0.status != .pending }.count)")
                            .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Debug Actions")) {
                    Button("Print Debug Info") {
                        dailyResetManager.printResetDebugInfo()
                    }
                    
                    Button("Force Reset Now") {
                        dailyResetManager.forceResetWithDebug()
                    }
                    .foregroundColor(.red)
                    
                    Button("Override Last Reset Date") {
                        // Set last reset to yesterday to force a reset
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                        let yesterdayString = dateFormatter.string(from: yesterday)
                        UserDefaults.standard.set(yesterdayString, forKey: "LastResetDate")
                        dailyResetManager.printResetDebugInfo()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Debug Reset")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
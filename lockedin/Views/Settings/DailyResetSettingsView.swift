//
//  DailyResetSettingsView.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//

import SwiftUI

struct DailyResetSettingsView: View {
    @ObservedObject var dailyResetManager: DailyResetManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var enableDailyReset = true // Default to true
    @State private var showResetConfirmation = false
    @State private var showingInfo = false
    
    // Date formatter for last reset display
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Reset")) {
                    Toggle("Reset Tasks Daily", isOn: $enableDailyReset)
                        .onChange(of: enableDailyReset) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "EnableDailyReset")
                            dailyResetManager.setDailyResetEnabled(newValue)
                        }
                    
                    Text("Tasks will automatically reset at midnight each day, giving you a fresh start.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show last reset time if available
                    if let lastResetDate = UserDefaults.standard.object(forKey: "LastResetDate") as? Date {
                        HStack {
                            Text("Last reset:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dateFormatter.string(from: lastResetDate))
                                .foregroundColor(.primary)
                        }
                        .font(.caption)
                    }
                }
                
                Section(header: Text("Reset Now")) {
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Reset Tasks Now")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("This will reset all your tasks immediately. Completed tasks will return to pending status.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Information about midnight reset
                Section(header: Text("How It Works")) {
                    Text("Each day at midnight (12:00 AM), any tasks that were completed the previous day will be reset to pending. New tasks you add will remain until they're completed or reset.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Daily Reset Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Load saved setting
                enableDailyReset = UserDefaults.standard.bool(forKey: "EnableDailyReset")
            }
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text("Reset Tasks Now?"),
                    message: Text("This will reset all completed tasks to pending status immediately. This cannot be undone."),
                    primaryButton: .default(Text("Reset")) {
                        dailyResetManager.resetTasks()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

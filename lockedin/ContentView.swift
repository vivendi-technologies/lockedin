//
//  ContentView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var appRestrictionManager = AppRestrictionManager()
    @State private var showingAppSettings = false
    @State private var authorizationRequested = false
    
    var body: some View {
        ZStack {
            TaskListView(taskManager: taskManager)
                .onAppear {
                    // Inject the manager into taskManager
                    taskManager.appRestrictionManager = appRestrictionManager
                }
                .overlay(
                    VStack {
                        Spacer()
                        
                        // App restriction status banner - use the shared instance
                        if appRestrictionManager.isRestrictionActive {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white)
                                
                                Text("Apps restricted until tasks are completed")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAppSettings = true
                                }) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(radius: 2)
                        }
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingAppSettings = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
        }
        .onAppear {
            requestAuthorizationIfNeeded()
        }
        .sheet(isPresented: $showingAppSettings) {
            // Use the shared restriction manager
            AppSelectionView(restrictionManager: appRestrictionManager)
        }
        // Make the restriction manager available to child views
        .environmentObject(appRestrictionManager)
    }
    
    // Request Screen Time authorization when the app first launches
    private func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        
        _Concurrency.Task {
            // Mark as requested to prevent multiple attempts
            authorizationRequested = true
            
            // Request authorization (doesn't return a boolean)
            await appRestrictionManager.requestAuthorization()
            
            // Check authorization status after the request
            if appRestrictionManager.isAuthorized {
                // Apply default restrictions if it's the first launch
                if taskManager.tasks.isEmpty {
                    // Add some default tasks for first-time users
                    taskManager.addTask(.predefined(title: "Morning Meditation", description: "Complete a 10-minute meditation session"))
                    taskManager.addTask(.predefined(title: "Read", description: "Read at least 10 pages of a book"))
                    
                    // Enable restrictions using the shared instance
                    appRestrictionManager.enableRestrictions()
                }
            }
        }
    }
}

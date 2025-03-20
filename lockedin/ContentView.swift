//
//  ContentView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

// Add this to ContentView.swift
import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAppSettings = false
    @State private var authorizationRequested = false
    
    var body: some View {
        ZStack {
            TaskListView(taskManager: taskManager)
                .overlay(
                    VStack {
                        Spacer()
                        
                        // App restriction status banner
                        if taskManager.restrictionManager.isRestrictionActive {
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
            AppSelectionView(restrictionManager: taskManager.restrictionManager)
        }
    }
    
    // Request Screen Time authorization when the app first launches
    private func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        
        _Concurrency.Task {
            let authorized = await taskManager.restrictionManager.requestAuthorization()
            if authorized {
                // Apply default restrictions if it's the first launch
                if taskManager.tasks.isEmpty {
                    // Add some default tasks for first-time users
                    taskManager.addTask(.predefined(title: "Morning Meditation", description: "Complete a 10-minute meditation session"))
                    taskManager.addTask(.predefined(title: "Read", description: "Read at least 10 pages of a book"))
                    
                    // Enable restrictions
                    taskManager.restrictionManager.enableRestrictions()
                }
            }
            authorizationRequested = true
        }
    }
}

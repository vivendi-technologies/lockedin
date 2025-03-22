import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var appRestrictionManager: AppRestrictionManager
    @EnvironmentObject var dailyResetManager: DailyResetManager
    
    @State private var showingAppSettings = false
    @State private var authorizationRequested = false
    @State private var showingResetBanner = false
    @State private var showingDebugView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // App restriction banner now appears below the navigation title
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
                    .padding(.top, 4)
                    .shadow(radius: 2)
                }
                
                // Main task list view
                TaskListView(taskManager: taskManager)
                    .onAppear {
                        // Inject the manager into taskManager
                        taskManager.appRestrictionManager = appRestrictionManager
                    }
            }
            .navigationTitle("Bloomer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            showingAppSettings = true
                        }) {
                            Label("App Restrictions", systemImage: "lock.shield")
                        }
                        
                        NavigationLink(destination:
                            DailyResetSettingsView(dailyResetManager: dailyResetManager)
                        ) {
                            Label("Daily Reset", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            // Overlay for task reset banner only - no longer includes the restriction banner
            .overlay(
                VStack {
                    if showingResetBanner {
                        TaskResetBanner(isVisible: $showingResetBanner)
                    }
                    
                    Spacer()
                }
            )
        }
        // Debug button overlay
        .overlay(
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingDebugView = true
                    }) {
                        Text("Debug")
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding()
                    .opacity(0.7)
                }
            }
        )
        .onAppear {
            requestAuthorizationIfNeeded()
        }
        // Monitor for daily resets
        .onReceive(dailyResetManager.$didResetToday) { didReset in
            if didReset {
                withAnimation {
                    showingResetBanner = true
                }
            }
        }
        .sheet(isPresented: $showingAppSettings) {
            // Use the shared restriction manager
            AppSelectionView(restrictionManager: appRestrictionManager)
        }
        .sheet(isPresented: $showingDebugView) {
            DebugViewController(dailyResetManager: dailyResetManager, taskManager: taskManager)
        }
    }
    
    // Request Screen Time authorization when the app first launches
    func requestAuthorizationIfNeeded() {
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
